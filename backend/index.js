require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const pool = require('./src/config/db');
const redisClient = require('./src/config/redisClient');
const { getWrappedDataForUser } = require('./src/controllers/wrappedQueriesController');
const { kmpContains } = require('./src/algorithms/stringMatch');
const { runLeaderboardHeapSort } = require('./src/algorithms/heapSort');
const { verifyMissionPrerequisites, hasProgressionPath } = require('./src/algorithms/dfs');
const supabase = require('./src/config/supabaseClient');

/**
 * Helper function to evaluate and promote a user's tier if they meet the 
 * XP requirements for a higher tier.
 */
async function createNotification(userUid, senderUid, type, title, message) {
  try {
    await pool.query(
      `INSERT INTO notifications (user_uid, sender_uid, type, title, message)
       VALUES ($1, $2, $3, $4, $5)`,
      [userUid, senderUid || null, type, title, message]
    );
  } catch (err) {
    console.error('Error creating notification:', err.message);
  }
}

async function checkAndPromoteUserTier(userId) {
  const userRes = await pool.query('SELECT total_xp, current_tier_id FROM users WHERE uid = $1', [userId]);
  if (userRes.rows.length === 0) return false;

  const { total_xp, current_tier_id } = userRes.rows[0];

  const { rows: allTiers } = await pool.query('SELECT id, required_xp, tier_name FROM tiers ORDER BY required_xp DESC');

  for (const tier of allTiers) {
    if (total_xp >= tier.required_xp) {
      if (tier.id !== current_tier_id) {
        await pool.query('UPDATE users SET current_tier_id = $1 WHERE uid = $2', [tier.id, userId]);
        await createNotification(userId, null, 'promotion', 'Tier Promoted!', `Congratulations! You have been promoted to the ${tier.tier_name} tier.`);
        return true;
      }
      break;
    }
  }

  return false;
}

/**
 * Helper function to log user actions to activity_logs table.
 */
async function logUserActivity(userUid, actionDescription) {
  try {
    await pool.query(
      `INSERT INTO activity_logs (user_uid, action_description) VALUES ($1, $2)`,
      [userUid, actionDescription]
    );
  } catch (err) {
    console.error('Error logging user activity:', err.message);
  }
}

/**
 * Helper function to dynamically calculate a user's daily streak from activity_logs.
 */
async function getUserDailyStreak(userId) {
  try {
    const result = await pool.query(
      `SELECT DISTINCT TO_CHAR(created_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD') as activity_date 
       FROM activity_logs 
       WHERE user_uid = $1 
       ORDER BY activity_date DESC`,
      [userId]
    );

    if (result.rows.length === 0) {
      return 0;
    }

    const dates = result.rows.map(row => row.activity_date);

    // Get today and yesterday in Asia/Manila timezone
    const now = new Date();
    const todayStr = now.toLocaleDateString('sv-SE', { timeZone: 'Asia/Manila' });

    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toLocaleDateString('sv-SE', { timeZone: 'Asia/Manila' });

    // If the latest activity is neither today nor yesterday, the streak is broken (0)
    if (dates[0] !== todayStr && dates[0] !== yesterdayStr) {
      return 0;
    }

    let streak = 1;
    let currentDate = new Date(dates[0]);

    for (let i = 1; i < dates.length; i++) {
      const nextDate = new Date(dates[i]);
      // Calculate difference in days
      const diffTime = currentDate - nextDate;
      const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays === 1) {
        streak++;
        currentDate = nextDate;
      } else if (diffDays > 1) {
        break; // Gap detected, streak ends
      }
    }

    return streak;
  } catch (err) {
    console.error('Error calculating daily streak:', err);
    return 0;
  }
}


const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret';

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// --- AUTHENTICATION MIDDLEWARE ---
async function protect(req, res, next) {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, JWT_SECRET);
      req.userId = decoded.id;
      return next();
    } catch (error) {
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }
  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token available' });
  }
}

async function optionalProtect(req, res, next) {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, JWT_SECRET);
      req.userId = decoded.id;
    } catch (error) { }
  }
  return next();
}

// --- DYNAMIC ROUTES ---

// 1. REGISTER A NEW USER (FIXED TIER INITIALIZATION)
app.post('/api/auth/register', async (req, res) => {
  const { name, username, email, password, environmentalScore, city, province } = req.body;

  // Clean fallback: use 'username' if provided, otherwise grab the 'Full Name' input
  const finalUsername = username || name;

  if (!finalUsername || !email || !password) {
    return res.status(400).json({ error: 'Username, email, and password are required.' });
  }

  try {
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 🌟 FIXED: Added current_tier_id to prevent profiles from loading as blank/null units
    // Force default environmental score / total_xp to start explicitly at 0
    const newUser = await pool.query(
      `INSERT INTO users (username, email, password_hash, total_xp, city, province, current_tier_id) 
       VALUES ($1, $2, $3, $4, $5, $6, $7) 
       RETURNING uid, username, email, total_xp, current_tier_id`,
      [
        finalUsername,
        email,
        passwordHash,
        0,
        city || 'Manila',
        province || 'Metro Manila',
        1 // 👈 Automatically seeds fresh accounts into baseline Tier 1
      ]
    );

    const createdUser = newUser.rows[0];
    const token = jwt.sign({ id: createdUser.uid }, JWT_SECRET, { expiresIn: '30d' });

    // Log the user registration activity in activity_logs
    await logUserActivity(createdUser.uid, 'Registered user account.');

    res.status(201).json({
      success: true,
      message: 'User registered successfully in the cloud!',
      token,
      user: {
        ...createdUser,
        daily_streak: 0
      }
    });
  } catch (err) {
    console.error('Registration SQL Error:', err.message);
    res.status(400).json({ error: err.message });
  }
});

// 2. LOGIN USER & ISSUE JWT TOKEN
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    // Queries database using clean email lookup
    const userResult = await pool.query(
      `SELECT u.*, t.tier_name 
       FROM users u 
       LEFT JOIN tiers t ON u.current_tier_id = t.id 
       WHERE u.email = $1`,
      [email]
    );
    if (userResult.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    const user = userResult.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    // Signs token using your primary key column: user.uid
    const token = jwt.sign({ id: user.uid }, JWT_SECRET, { expiresIn: '30d' });

    // Log the user login activity in activity_logs
    await logUserActivity(user.uid, 'Logged in to account.');

    // Fetch the daily streak
    const streak = await getUserDailyStreak(user.uid);

    res.json({
      token,
      user: {
        uid: user.uid,
        username: user.username,
        email: user.email,
        total_xp: user.total_xp,
        current_tier_id: user.current_tier_id,
        tier_name: user.tier_name,
        daily_streak: streak
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. GET PROFILE OF THE LOGGED-IN USER
app.get('/api/users/me', protect, async (req, res) => {
  try {
    const userResult = await pool.query(
      `SELECT u.uid, u.username, u.email, u.total_xp, u.city, u.province, u.region, t.tier_name, u.current_tier_id, u.profile_pic_url, u.bio
       FROM users u 
       LEFT JOIN tiers t ON u.current_tier_id = t.id 
       WHERE u.uid = $1`,
      [req.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'User profile not found' });
    }

    const user = userResult.rows[0];
    user.daily_streak = await getUserDailyStreak(req.userId);

    return res.status(200).json(user);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET POSTS OF THE LOGGED-IN USER
app.get('/api/users/me/posts', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.id, u.uid AS author_uid, u.username AS author_name, u.profile_pic_url, p.caption, p.image_url, p.created_at, c.name as tag_text, p.mission_id,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM post_downvotes pd WHERE pd.post_id = p.id) as downvotes_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) as comments_count,
        EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_uid = $1) as is_liked_by_me,
        EXISTS(SELECT 1 FROM post_downvotes pd WHERE pd.post_id = p.id AND pd.user_uid = $1) as is_downvoted_by_me
       FROM posts p
       INNER JOIN users u ON p.user_uid = u.uid
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.user_uid = $1
       ORDER BY p.created_at DESC`,
      [req.userId]
    );
    return res.status(200).json(rows);
  } catch (err) {
    console.error('GET /api/users/me/posts error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- UPDATE LOGGED-IN USER PROFILE ---
app.put('/api/users/me', protect, async (req, res) => {
  try {
    const { username, city, province } = req.body;
    if (!username) {
      return res.status(400).json({ error: 'Username is required' });
    }
    
    const result = await pool.query(
      `UPDATE users 
       SET username = $1, city = $2, province = $3 
       WHERE uid = $4 
       RETURNING uid, username, email, total_xp, city, province`,
      [username, city || 'Manila', province || 'Metro Manila', req.userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User profile not found' });
    }
    
    const updatedUser = result.rows[0];
    updatedUser.daily_streak = await getUserDailyStreak(req.userId);

    // Log the profile update activity
    await logUserActivity(req.userId, 'Updated user profile details.');

    return res.status(200).json({
      message: 'Profile updated successfully!',
      user: updatedUser
    });
  } catch (err) {
    console.error('Update profile error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- PUT /api/users/profile (UPDATE DETAILS AND BIOGRAPHY) ---
app.put('/api/users/profile', protect, async (req, res) => {
  try {
    const { username, city, province, region, bio } = req.body;
    if (!username) {
      return res.status(400).json({ error: 'Username is required' });
    }
    await pool.query(
      `UPDATE users 
       SET username = $1, city = $2, province = $3, region = $4, bio = $5 
       WHERE uid = $6`,
      [username, city || 'Manila', province || 'Metro Manila', region || null, bio, req.userId]
    );
    await clearLeaderboardCache();
    return res.status(200).json({ success: true, message: 'Profile updated successfully.' });
  } catch (err) {
    console.error('PUT /api/users/profile error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- POST /api/users/report (SAFETY REPORT ACCOUNT) ---
app.post('/api/users/report', protect, async (req, res) => {
  try {
    const { target_user_uid, reason } = req.body;
    const reporter_uid = req.userId;

    if (!target_user_uid || !reason) {
      return res.status(400).json({ error: 'Target user UID and reason are required.' });
    }

    await pool.query(
      `INSERT INTO user_reports (target_user_uid, reporter_uid, reason) 
       VALUES ($1, $2, $3)`,
      [target_user_uid, reporter_uid, reason]
    );

    return res.status(201).json({ success: true, message: 'Report logged successfully.' });
  } catch (err) {
    console.error('POST /api/users/report error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// 5. GET LEADERBOARD OF TOP USERS (Dynamic with Heap Sort)
app.get('/api/users/leaderboard', optionalProtect, async (req, res) => {
  try {
    const { city, province, region, timeframe, type } = req.query;
    // city, province, region: optional geographic filters
    // timeframe: 'daily', 'weekly', 'monthly', 'yearly', 'all-time'
    // type: 'friends' or 'global'

    const cacheKey = `leaderboard:${type || 'global'}:${req.userId || 'anon'}:${city || 'all'}:${province || 'all'}:${region || 'all'}:${timeframe || 'all-time'}`;
    let cached = null;
    if (redisClient.isOpen) {
      cached = await redisClient.get(cacheKey);
    }
    if (cached) {
      return res.status(200).json(JSON.parse(cached));
    }

    let query = `
      SELECT u.uid, u.username, u.city, u.province, u.region, t.tier_name, u.total_xp, u.profile_pic_url
      FROM users u
      LEFT JOIN tiers t ON u.current_tier_id = t.id
      WHERE 1=1
    `;
    const params = [];

    if (type === 'friends') {
      if (!req.userId) {
        return res.status(401).json({ error: 'Authentication required for friends leaderboard.' });
      }
      params.push(req.userId);
      query += ` AND (u.uid IN (
        SELECT friend_uid FROM friendships WHERE user_uid = $${params.length} AND status = 'accepted'
        UNION
        SELECT user_uid FROM friendships WHERE friend_uid = $${params.length} AND status = 'accepted'
        UNION
        SELECT $${params.length}::uuid
      ))`;
    }

    if (city) {
      params.push(city);
      query += ` AND u.city = $${params.length}`;
    }
    if (province) {
      params.push(province);
      query += ` AND u.province = $${params.length}`;
    }
    if (region) {
      params.push(region);
      query += ` AND u.region = $${params.length}`;
    }

    // For specific timeframes, we will aggregate XP on the fly
    if (timeframe && timeframe !== 'all-time') {
      let interval = '1 year';
      if (timeframe === 'daily') interval = '1 day';
      if (timeframe === 'weekly') interval = '1 week';
      if (timeframe === 'monthly') interval = '1 month';

      // We overwrite total_xp with the aggregated timeframe XP
      query = `
        SELECT u.uid, u.username, u.city, u.province, u.region, t.tier_name, u.profile_pic_url,
          CAST(COALESCE((
            SELECT SUM(m.xp_reward) 
            FROM user_missions um 
            JOIN missions m ON um.mission_id = m.id 
            WHERE um.user_uid = u.uid AND um.completed_at >= NOW() - INTERVAL '${interval}'
          ), 0) +
          COALESCE((
            SELECT SUM(c.xp_weight)
            FROM posts p
            JOIN categories c ON p.category_id = c.id
            WHERE p.user_uid = u.uid AND p.created_at >= NOW() - INTERVAL '${interval}'
          ), 0) AS INTEGER) AS total_xp
        FROM users u
        LEFT JOIN tiers t ON u.current_tier_id = t.id
        WHERE 1=1
      `;
      // rebuild params
      params.length = 0;

      if (type === 'friends') {
        params.push(req.userId);
        query += ` AND (u.uid IN (
          SELECT friend_uid FROM friendships WHERE user_uid = $${params.length} AND status = 'accepted'
          UNION
          SELECT user_uid FROM friendships WHERE friend_uid = $${params.length} AND status = 'accepted'
          UNION
          SELECT $${params.length}::uuid
        ))`;
      }

      if (city) {
        params.push(city);
        query += ` AND u.city = $${params.length}`;
      }
      if (province) {
        params.push(province);
        query += ` AND u.province = $${params.length}`;
      }
      if (region) {
        params.push(region);
        query += ` AND u.region = $${params.length}`;
      }
    }

    const { rows } = await pool.query(query, params);

    // Use Heap Sort to establish standings
    const sorted = runLeaderboardHeapSort(rows);

    // Isolate top 50
    const top50 = sorted.slice(0, 50);

    // Cache the result for 60 seconds
    if (redisClient.isOpen) {
      await redisClient.set(cacheKey, JSON.stringify(top50), { EX: 60 });
    }

    return res.status(200).json(top50);
  } catch (err) {
    console.error('Leaderboard error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// 4. GET ECOWRAPPED SUMMARY FOR THE LOGGED-IN USER
app.get('/api/users/wrapped', protect, async (req, res) => {
  try {
    const data = await getWrappedDataForUser(req.userId);
    if (!data) {
      return res.status(404).json({ message: 'No wrapped data found for this user.' });
    }
    return res.status(200).json(data);
  } catch (err) {
    console.error('[GET /api/users/wrapped]', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- SEARCH BUDDY (peer-discovery via KMP string match) ---
app.post('/api/users/search-buddy', protect, async (req, res) => {
  try {
    const { query } = req.body;
    if (!query) {
      return res.status(400).json({ error: 'Search query is required' });
    }

    const { rows: allUsers } = await pool.query(
      `SELECT u.uid::text as uid, u.username, u.total_xp, u.city, u.province, t.tier_name
       FROM users u
       LEFT JOIN tiers t ON u.current_tier_id = t.id`
    );

    const matches = [];
    for (const u of allUsers) {
      if (kmpContains(u.uid, query)) {
        matches.push(u);
      }
    }

    if (matches.length > 0) {
      return res.status(200).json(matches);
    } else {
      return res.status(404).json({ error: 'Buddy UID not found' });
    }
  } catch (err) {
    console.error('Search buddy error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- GET PROFILE OF A SPECIFIC USER ---
app.get('/api/users/:uid', protect, async (req, res) => {
  try {
    const userResult = await pool.query(
      `SELECT u.uid, u.username, u.email, u.total_xp, u.city, u.province, u.region, t.tier_name, u.current_tier_id, u.profile_pic_url, u.bio,
              f.status AS friendship_status,
              f.user_uid AS friendship_initiator
       FROM users u 
       LEFT JOIN tiers t ON u.current_tier_id = t.id 
       LEFT JOIN friendships f ON (
         (f.user_uid = $2 AND f.friend_uid = u.uid) OR
         (f.user_uid = u.uid AND f.friend_uid = $2)
       )
       WHERE u.uid = $1`,
      [req.params.uid, req.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'User profile not found' });
    }

    const user = userResult.rows[0];
    user.daily_streak = await getUserDailyStreak(user.uid);

    return res.status(200).json(user);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// --- GET POSTS OF A SPECIFIC USER ---
app.get('/api/users/:uid/posts', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.id, u.uid AS author_uid, u.username AS author_name, u.profile_pic_url, p.caption, p.image_url, p.created_at, c.name as tag_text, p.mission_id,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM post_downvotes pd WHERE pd.post_id = p.id) as downvotes_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) as comments_count,
        EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_uid = $2) as is_liked_by_me,
        EXISTS(SELECT 1 FROM post_downvotes pd WHERE pd.post_id = p.id AND pd.user_uid = $2) as is_downvoted_by_me
       FROM posts p
       INNER JOIN users u ON p.user_uid = u.uid
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.user_uid = $1
       ORDER BY p.created_at DESC`,
      [req.params.uid, req.userId]
    );
    return res.status(200).json(rows);
  } catch (err) {
    console.error('GET /api/users/:uid/posts error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- GET FRIENDS OF A SPECIFIC USER ---
app.get('/api/users/:uid/friends', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT u.uid, u.username, u.total_xp, t.tier_name, u.profile_pic_url
       FROM users u
       LEFT JOIN tiers t ON u.current_tier_id = t.id
       WHERE u.uid IN (
         SELECT friend_uid FROM friendships WHERE user_uid = $1 AND status = 'accepted'
         UNION
         SELECT user_uid FROM friendships WHERE friend_uid = $1 AND status = 'accepted'
       )`,
      [req.params.uid]
    );
    return res.status(200).json(rows);
  } catch (err) {
    console.error('GET /api/users/:uid/friends error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- GET ECOWRAP DATA OF A SPECIFIC USER ---
app.get('/api/users/:uid/wrapped', protect, async (req, res) => {
  try {
    const data = await getWrappedDataForUser(req.params.uid);
    if (!data) {
      return res.status(404).json({ message: 'No wrapped data found for this user.' });
    }
    return res.status(200).json(data);
  } catch (err) {
    console.error('[GET /api/users/:uid/wrapped]', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- FRIEND SYSTEM ENDPOINTS ---

// Send Friend Request
app.post('/api/friends/request', protect, async (req, res) => {
  try {
    const { friendUid } = req.body;
    if (!friendUid) {
      return res.status(400).json({ error: 'friendUid is required' });
    }
    if (friendUid === req.userId) {
      return res.status(400).json({ error: 'Cannot add yourself as a friend' });
    }

    // Check if user exists
    const userRes = await pool.query('SELECT username FROM users WHERE uid = $1', [friendUid]);
    if (userRes.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if friendship already exists
    const friendCheck = await pool.query(
      `SELECT * FROM friendships 
       WHERE (user_uid = $1 AND friend_uid = $2) OR (user_uid = $2 AND friend_uid = $1)`,
      [req.userId, friendUid]
    );

    if (friendCheck.rows.length > 0) {
      const friendship = friendCheck.rows[0];
      if (friendship.status === 'accepted') {
        return res.status(400).json({ error: 'You are already friends' });
      }
      if (friendship.status === 'pending') {
        if (friendship.user_uid === req.userId) {
          return res.status(400).json({ error: 'Friend request already sent' });
        } else {
          return res.status(400).json({ error: 'You have a pending friend request from this user' });
        }
      }
      // If status is declined, update to pending with new initiator
      await pool.query(
        `UPDATE friendships 
         SET status = 'pending', user_uid = $1, friend_uid = $2, created_at = NOW()
         WHERE (user_uid = $1 AND friend_uid = $2) OR (user_uid = $2 AND friend_uid = $1)`,
        [req.userId, friendUid]
      );
    } else {
      // Create new request
      await pool.query(
        `INSERT INTO friendships (user_uid, friend_uid, status)
         VALUES ($1, $2, 'pending')`,
        [req.userId, friendUid]
      );
    }

    // Trigger notification
    const senderRes = await pool.query('SELECT username FROM users WHERE uid = $1', [req.userId]);
    const senderName = senderRes.rows[0]?.username || 'Eco Warrior';
    await createNotification(friendUid, req.userId, 'friend_request', 'Friend Request', `${senderName} sent you a friend request.`);

    return res.status(201).json({ message: 'Friend request sent successfully!' });
  } catch (err) {
    console.error('Send friend request error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// Get Pending Friend Requests Received
app.get('/api/friends/requests', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT f.user_uid AS requester_uid, u.username AS requester_name, u.profile_pic_url, f.created_at 
       FROM friendships f 
       JOIN users u ON f.user_uid = u.uid 
       WHERE f.friend_uid = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [req.userId]
    );
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Get friend requests error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// Accept Friend Request
app.post('/api/friends/accept', protect, async (req, res) => {
  try {
    const { requesterUid } = req.body;
    if (!requesterUid) {
      return res.status(400).json({ error: 'requesterUid is required' });
    }

    const result = await pool.query(
      `UPDATE friendships 
       SET status = 'accepted' 
       WHERE user_uid = $1 AND friend_uid = $2 AND status = 'pending'
       RETURNING *`,
      [requesterUid, req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'No pending friend request found from this user.' });
    }

    // Trigger notification to the requester
    const acceptorRes = await pool.query('SELECT username FROM users WHERE uid = $1', [req.userId]);
    const acceptorName = acceptorRes.rows[0]?.username || 'Eco Warrior';
    await createNotification(requesterUid, req.userId, 'friend_accepted', 'Friend Request Accepted', `${acceptorName} accepted your friend request.`);

    return res.status(200).json({ message: 'Friend request accepted successfully!' });
  } catch (err) {
    console.error('Accept friend request error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// Decline Friend Request (Delete row)
app.post('/api/friends/decline', protect, async (req, res) => {
  try {
    const { requesterUid } = req.body;
    if (!requesterUid) {
      return res.status(400).json({ error: 'requesterUid is required' });
    }

    const result = await pool.query(
      `DELETE FROM friendships 
       WHERE user_uid = $1 AND friend_uid = $2 AND status = 'pending'
       RETURNING *`,
      [requesterUid, req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'No pending friend request found from this user.' });
    }

    return res.status(200).json({ message: 'Friend request declined successfully!' });
  } catch (err) {
    console.error('Decline friend request error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// GET Friends Feed
app.get('/api/feed/friends', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.id, u.uid AS author_uid, u.username AS author_name, u.profile_pic_url, p.caption, p.image_url, p.created_at, c.name as tag_text, p.mission_id,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM post_downvotes pd WHERE pd.post_id = p.id) as downvotes_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) as comments_count,
        EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_uid = $1) as is_liked_by_me,
        EXISTS(SELECT 1 FROM post_downvotes pd WHERE pd.post_id = p.id AND pd.user_uid = $1) as is_downvoted_by_me
       FROM posts p
       INNER JOIN users u ON p.user_uid = u.uid
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.user_uid IN (
         SELECT friend_uid FROM friendships WHERE user_uid = $1 AND status = 'accepted'
         UNION
         SELECT user_uid FROM friendships WHERE friend_uid = $1 AND status = 'accepted'
       )
       ORDER BY p.created_at DESC`,
      [req.userId]
    );
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Get friends feed error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- NOTIFICATION SYSTEM ENDPOINTS ---

// Get Notifications
app.get('/api/notifications', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT n.id, n.type, n.title, n.message, n.is_read, n.created_at, n.sender_uid, u.username as sender_name
       FROM notifications n
       LEFT JOIN users u ON n.sender_uid = u.uid
       WHERE n.user_uid = $1
       ORDER BY n.created_at DESC`,
      [req.userId]
    );
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Get notifications error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// Mark Notification as Read
app.post('/api/notifications/:id/read', protect, async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE notifications 
       SET is_read = true 
       WHERE id = $1 AND user_uid = $2 
       RETURNING *`,
      [req.params.id, req.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('Mark notification as read error:', err);
    return res.status(500).json({ error: err.message });
  }
});

async function clearLeaderboardCache() {
  if (redisClient && redisClient.isOpen) {
    try {
      const keys = await redisClient.keys('leaderboard:*');
      if (keys.length > 0) {
        await redisClient.del(keys);
      }
    } catch (e) {
      console.error('Error clearing leaderboard cache:', e);
    }
  }
}

// 6. GET /api/challenges/daily
app.get('/api/challenges/daily', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, title, description, xp_reward, tier_id FROM missions WHERE is_daily = true'
    );
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 6b. POST /api/missions/:id/complete
app.post('/api/missions/:id/complete', protect, async (req, res) => {
  try {
    const missionId = parseInt(req.params.id);
    const userId = req.userId;

    // 1. Insert into user_missions
    const missionRes = await pool.query('SELECT xp_reward, tier_id FROM missions WHERE id = $1', [missionId]);
    if (missionRes.rows.length === 0) return res.status(404).json({ error: 'Mission not found' });
    const { xp_reward, tier_id: targetTierId } = missionRes.rows[0];

    await pool.query(
      'INSERT INTO user_missions (user_uid, mission_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [userId, missionId]
    );

    // Add XP
    await pool.query('UPDATE users SET total_xp = total_xp + $1 WHERE uid = $2', [xp_reward, userId]);

    // Log the mission completion activity
    await logUserActivity(userId, `Completed mission: ${missionId}`);

    // Clear leaderboard cache so it dynamically updates
    await clearLeaderboardCache();

    // 2. DFS Verification for Tier Promotion
    const promoted = await checkAndPromoteUserTier(userId);

    if (promoted) {
      return res.status(200).json({ message: 'Mission completed! You have been promoted to a new tier!', promoted: true });
    }

    return res.status(200).json({ message: 'Mission completed!', promoted: false });
  } catch (err) {
    console.error('Mission complete error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// 7. GET /api/feed/trending -> Satisfies the community social impact feed
app.get('/api/feed/trending', optionalProtect, async (req, res) => {
  try {
    const userId = req.userId || null;
    const { rows } = await pool.query(
      `SELECT p.id, u.uid AS author_uid, u.username AS author_name, u.profile_pic_url, p.caption, p.image_url, p.created_at, c.name as tag_text, p.mission_id,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM post_downvotes pd WHERE pd.post_id = p.id) as downvotes_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) as comments_count,
        EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_uid = $1) as is_liked_by_me,
        EXISTS(SELECT 1 FROM post_downvotes pd WHERE pd.post_id = p.id AND pd.user_uid = $1) as is_downvoted_by_me
       FROM posts p
       INNER JOIN users u ON p.user_uid = u.uid
       LEFT JOIN categories c ON p.category_id = c.id
       ORDER BY p.created_at DESC`,
      [userId]
    );
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 7b. POST /api/posts -> Creates a new post with direct Supabase Storage integration
const FLAGGED_TERMS = ['badword1', 'spamlink', 'toxicphrase'];
app.post('/api/posts', protect, upload.single('image'), async (req, res) => {
  const { caption, category_id, mission_id } = req.body;
  let image_url = null;

  try {
    const textToCheck = caption || '';
    for (const term of FLAGGED_TERMS) {
      if (kmpContains(textToCheck, term)) {
        return res.status(400).json({
          error: "Post blocked: Content violates EcoEcho's community guidelines."
        });
      }
    }

    if (req.file) {
      try {
        const bucketName = process.env.SUPABASE_BUCKET_NAME || 'post-images';
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(req.file.originalname) || '.jpg';
        const filename = `${uniqueSuffix}${ext}`;

        // Upload file buffer directly to Supabase Cloud Storage Buckets
        const { data, error } = await supabase.storage
          .from(bucketName)
          .upload(filename, req.file.buffer, {
            contentType: req.file.mimetype,
            upsert: false
          });

        if (error) {
          throw new Error(`Supabase storage error: ${error.message}`);
        }

        // Retrieve the cloud CDN destination link
        const { data: publicUrlData } = supabase.storage
          .from(bucketName)
          .getPublicUrl(filename);

        image_url = publicUrlData.publicUrl;
      } catch (uploadErr) {
        console.error('Image upload to Supabase failed:', uploadErr);
        return res.status(500).json({ error: `Image upload failed: ${uploadErr.message}` });
      }
    } else {
      image_url = req.body.image_url || 'https://picsum.photos/400/300';
    }

    let awardedXp = 50; // Baseline post XP
    if (mission_id) {
      const parsedMissionId = parseInt(mission_id);
      const missionRes = await pool.query('SELECT * FROM missions WHERE id = $1', [parsedMissionId]);
      if (missionRes.rows.length === 0) {
        return res.status(400).json({ error: 'Mission not found.' });
      }
      const mission = missionRes.rows[0];

      // Cross-verify category_id aligns with mission
      let expectedCategoryId = null;
      if (parsedMissionId === 1) {
        expectedCategoryId = 4; // Energy Saving
      } else if (parsedMissionId === 2) {
        expectedCategoryId = 4; // Energy Saving (or whichever applies)
      } else if (parsedMissionId === 3) {
        expectedCategoryId = 3; // Recycling
      } else if (parsedMissionId === 4) {
        expectedCategoryId = 1; // Tree Planting
      }

      const postCategoryId = category_id ? parseInt(category_id) : null;
      if (expectedCategoryId !== null && postCategoryId !== expectedCategoryId) {
        return res.status(400).json({
          error: `Verification failed: Mission "${mission.title}" requires category ID ${expectedCategoryId}, but post is categorized under ${postCategoryId}.`
        });
      }

      // Record completion log inside user_missions
      await pool.query(
        'INSERT INTO user_missions (user_uid, mission_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
        [req.userId, parsedMissionId]
      );

      awardedXp += mission.xp_reward;
    }

    const newPost = await pool.query(
      `INSERT INTO posts (user_uid, caption, category_id, image_url, mission_id)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.userId, textToCheck, category_id ? parseInt(category_id) : null, image_url, mission_id ? parseInt(mission_id) : null]
    );

    await pool.query(
      `UPDATE users SET total_xp = total_xp + $1 WHERE uid = $2`,
      [awardedXp, req.userId]
    );

    // Log the post creation activity
    await logUserActivity(req.userId, `Created post: ${caption || ''}`);

    // Clear leaderboard cache so it dynamically updates
    await clearLeaderboardCache();

    const promoted = await checkAndPromoteUserTier(req.userId);

    res.status(201).json({
      success: true,
      message: 'Post created successfully!',
      post: newPost.rows[0],
      promoted
    });
  } catch (err) {
    console.error('POST /api/posts error:', err);
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/posts/:id -> Authenticated post deletion with XP deduction reversal
app.delete('/api/posts/:id', protect, async (req, res) => {
  try {
    const postId = req.params.id;
    const postRes = await pool.query('SELECT user_uid FROM posts WHERE id = $1', [postId]);
    if (postRes.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found.' });
    }
    const post = postRes.rows[0];

    // Authorization check
    if (post.user_uid !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized: You are not the author of this post.' });
    }

    // Revert users.total_xp (clamped at 0) - FLAT 50 XP DEDUCTION
    await pool.query(
      `UPDATE users 
       SET total_xp = GREATEST(0, total_xp - 50) 
       WHERE uid = $1`,
      [req.userId]
    );

    // Delete post record
    await pool.query('DELETE FROM posts WHERE id = $1', [postId]);

    // Clear leaderboard cache
    await clearLeaderboardCache();

    return res.status(200).json({ success: true, message: 'Post deleted successfully.' });
  } catch (err) {
    console.error('DELETE /api/posts/:id error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// PUT /api/users/profile-picture -> Cloud avatar picture upload and DB save
app.put('/api/users/profile-picture', protect, upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No image file uploaded.' });
  }

  try {
    const bucketName = process.env.SUPABASE_BUCKET_NAME || 'post-images';
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(req.file.originalname) || '.jpg';
    const filename = `avatars/${req.userId}-${uniqueSuffix}${ext}`;

    // Upload buffer to Supabase Cloud Storage
    const { data, error } = await supabase.storage
      .from(bucketName)
      .upload(filename, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: true
      });

    if (error) {
      throw new Error(`Supabase storage error: ${error.message}`);
    }

    // Public URL
    const { data: publicUrlData } = supabase.storage
      .from(bucketName)
      .getPublicUrl(filename);

    const publicUrl = publicUrlData.publicUrl;

    // Save public URL to DB
    await pool.query(
      'UPDATE users SET profile_pic_url = $1 WHERE uid = $2',
      [publicUrl, req.userId]
    );

    // Clear leaderboard cache
    await clearLeaderboardCache();

    return res.status(200).json({
      success: true,
      message: 'Profile picture updated successfully.',
      profile_pic_url: publicUrl
    });
  } catch (err) {
    console.error('PUT /api/users/profile-picture error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// 7c. GET /api/users/me/posts
app.get('/api/users/me/posts', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.id, u.uid AS author_uid, u.username AS author_name, u.profile_pic_url, p.caption, p.image_url, p.created_at, c.name as tag_text, p.mission_id,
        (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM post_downvotes pd WHERE pd.post_id = p.id) as downvotes_count,
        (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) as comments_count,
        EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_uid = $1) as is_liked_by_me,
        EXISTS(SELECT 1 FROM post_downvotes pd WHERE pd.post_id = p.id AND pd.user_uid = $1) as is_downvoted_by_me
       FROM posts p
       INNER JOIN users u ON p.user_uid = u.uid
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.user_uid = $1
       ORDER BY p.created_at DESC`,
      [req.userId]
    );
    return res.status(200).json(rows);
  } catch (err) {
    console.error('GET /api/users/me/posts error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// --- LIKES AND COMMENTS ---

app.post('/api/posts/:id/like', protect, async (req, res) => {
  try {
    const postId = req.params.id;
    await pool.query(
      'DELETE FROM post_downvotes WHERE post_id = $1 AND user_uid = $2',
      [postId, req.userId]
    );
    const likeRes = await pool.query(
      'INSERT INTO post_likes (post_id, user_uid) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING id',
      [postId, req.userId]
    );
    
    // Log the like activity
    await logUserActivity(req.userId, `Upvoted post: ${postId}`);

    // Send notification if a new like was registered
    if (likeRes.rows.length > 0) {
      const postRes = await pool.query('SELECT user_uid FROM posts WHERE id = $1', [postId]);
      if (postRes.rows.length > 0) {
        const authorUid = postRes.rows[0].user_uid;
        if (authorUid !== req.userId) {
          const userRes = await pool.query('SELECT username FROM users WHERE uid = $1', [req.userId]);
          const senderName = userRes.rows[0]?.username || 'Eco Warrior';
          await createNotification(authorUid, req.userId, 'like', 'New Like', `${senderName} liked your post.`);
        }
      }
    }
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/posts/:id/like', protect, async (req, res) => {
  try {
    const postId = req.params.id;
    await pool.query(
      'DELETE FROM post_likes WHERE post_id = $1 AND user_uid = $2',
      [postId, req.userId]
    );
    
    // Log the unlike activity
    await logUserActivity(req.userId, `Removed upvote on post: ${postId}`);

    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/posts/:id/downvote', protect, async (req, res) => {
  try {
    const postId = req.params.id;
    await pool.query(
      'DELETE FROM post_likes WHERE post_id = $1 AND user_uid = $2',
      [postId, req.userId]
    );
    await pool.query(
      'INSERT INTO post_downvotes (post_id, user_uid) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [postId, req.userId]
    );

    // Log the downvote activity
    await logUserActivity(req.userId, `Downvoted post: ${postId}`);

    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/posts/:id/downvote', protect, async (req, res) => {
  try {
    const postId = req.params.id;
    await pool.query(
      'DELETE FROM post_downvotes WHERE post_id = $1 AND user_uid = $2',
      [postId, req.userId]
    );

    // Log the remove downvote activity
    await logUserActivity(req.userId, `Removed downvote on post: ${postId}`);

    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/posts/:id/comments', optionalProtect, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.userId || null;
    const { rows } = await pool.query(
      `SELECT pc.id, pc.content, pc.created_at, pc.user_uid, u.username as author_name, u.profile_pic_url,
        (SELECT COUNT(*)::int FROM comment_likes cl WHERE cl.comment_id = pc.id) as likes_count,
        (SELECT COUNT(*)::int FROM comment_downvotes cd WHERE cd.comment_id = pc.id) as downvotes_count,
        EXISTS(SELECT 1 FROM comment_likes cl WHERE cl.comment_id = pc.id AND cl.user_uid = $1) as is_liked_by_me,
        EXISTS(SELECT 1 FROM comment_downvotes cd WHERE cd.comment_id = pc.id AND cd.user_uid = $1) as is_downvoted_by_me
       FROM post_comments pc 
       JOIN users u ON pc.user_uid = u.uid 
       WHERE pc.post_id = $2 
       ORDER BY pc.created_at ASC`,
      [userId, postId]
    );
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/posts/:id/comment', protect, async (req, res) => {
  try {
    const postId = req.params.id;
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: 'Content is required' });

    const { rows } = await pool.query(
      'INSERT INTO post_comments (post_id, user_uid, content) VALUES ($1, $2, $3) RETURNING *',
      [postId, req.userId, content]
    );

    // Log the comment activity
    await logUserActivity(req.userId, `Commented on post: ${postId}`);

    // Send notification to post owner
    const postRes = await pool.query('SELECT user_uid FROM posts WHERE id = $1', [postId]);
    if (postRes.rows.length > 0) {
      const authorUid = postRes.rows[0].user_uid;
      if (authorUid !== req.userId) {
        const userRes = await pool.query('SELECT username FROM users WHERE uid = $1', [req.userId]);
        const senderName = userRes.rows[0]?.username || 'Eco Warrior';
        await createNotification(authorUid, req.userId, 'comment', 'New Comment', `${senderName} commented on your post.`);
      }
    }

    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/comments/:commentId', protect, async (req, res) => {
  try {
    const { commentId } = req.params;
    const commentRes = await pool.query('SELECT user_uid FROM post_comments WHERE id = $1', [commentId]);
    if (commentRes.rows.length === 0) {
      return res.status(404).json({ error: 'Comment not found.' });
    }
    if (commentRes.rows[0].user_uid !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized: You are not the author of this comment.' });
    }
    await pool.query('DELETE FROM post_comments WHERE id = $1', [commentId]);
    res.status(200).json({ success: true, message: 'Comment deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/posts/:id/comment/:commentId', protect, async (req, res) => {
  try {
    const { commentId } = req.params;
    const commentRes = await pool.query('SELECT user_uid FROM post_comments WHERE id = $1', [commentId]);
    if (commentRes.rows.length === 0) {
      return res.status(404).json({ error: 'Comment not found.' });
    }
    if (commentRes.rows[0].user_uid !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized.' });
    }
    await pool.query('DELETE FROM post_comments WHERE id = $1', [commentId]);
    res.status(200).json({ success: true, message: 'Comment deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- REPORT POST ---
app.post('/api/posts/:id/report', protect, async (req, res) => {
  try {
    const postId = req.params.id;
    const { reason } = req.body;
    if (!reason) return res.status(400).json({ error: 'Reason is required' });

    await pool.query(
      'INSERT INTO post_reports (reporter_uid, post_id, reason) VALUES ($1, $2, $3)',
      [req.userId, postId, reason]
    );
    res.status(201).json({ success: true, message: 'Report submitted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- COMMENT VOTING ---
app.post('/api/comments/:id/like', protect, async (req, res) => {
  try {
    const commentId = req.params.id;
    await pool.query(
      'DELETE FROM comment_downvotes WHERE comment_id = $1 AND user_uid = $2',
      [commentId, req.userId]
    );
    await pool.query(
      'INSERT INTO comment_likes (comment_id, user_uid) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [commentId, req.userId]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/comments/:id/like', protect, async (req, res) => {
  try {
    const commentId = req.params.id;
    await pool.query(
      'DELETE FROM comment_likes WHERE comment_id = $1 AND user_uid = $2',
      [commentId, req.userId]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/comments/:id/downvote', protect, async (req, res) => {
  try {
    const commentId = req.params.id;
    await pool.query(
      'DELETE FROM comment_likes WHERE comment_id = $1 AND user_uid = $2',
      [commentId, req.userId]
    );
    await pool.query(
      'INSERT INTO comment_downvotes (comment_id, user_uid) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [commentId, req.userId]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/comments/:id/downvote', protect, async (req, res) => {
  try {
    const commentId = req.params.id;
    await pool.query(
      'DELETE FROM comment_downvotes WHERE comment_id = $1 AND user_uid = $2',
      [commentId, req.userId]
    );
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 8. GET /api/missions/daily
app.get('/api/missions/daily', protect, async (req, res) => {
  try {
    const userId = req.userId;

    // Fetch user analytics
    const analyticsRes = await pool.query(
      `SELECT 
        u.total_xp,
        COALESCE(t.tier_name, 'Tier 1') as tier_name,
        
        -- Week
        CAST(COALESCE((
          SELECT SUM(m.xp_reward) 
          FROM user_missions um 
          JOIN missions m ON um.mission_id = m.id 
          WHERE um.user_uid = u.uid AND um.completed_at >= NOW() - INTERVAL '7 days'
        ), 0) +
        COALESCE((
          SELECT SUM(c.xp_weight)
          FROM posts p
          JOIN categories c ON p.category_id = c.id
          WHERE p.user_uid = u.uid AND p.created_at >= NOW() - INTERVAL '7 days'
        ), 0) AS INTEGER) AS xp_week,
        
        -- Month
        CAST(COALESCE((
          SELECT SUM(m.xp_reward) 
          FROM user_missions um 
          JOIN missions m ON um.mission_id = m.id 
          WHERE um.user_uid = u.uid AND um.completed_at >= NOW() - INTERVAL '30 days'
        ), 0) +
        COALESCE((
          SELECT SUM(c.xp_weight)
          FROM posts p
          JOIN categories c ON p.category_id = c.id
          WHERE p.user_uid = u.uid AND p.created_at >= NOW() - INTERVAL '30 days'
        ), 0) AS INTEGER) AS xp_month,
        
        -- Year
        CAST(COALESCE((
          SELECT SUM(m.xp_reward) 
          FROM user_missions um 
          JOIN missions m ON um.mission_id = m.id 
          WHERE um.user_uid = u.uid AND um.completed_at >= NOW() - INTERVAL '365 days'
        ), 0) +
        COALESCE((
          SELECT SUM(c.xp_weight)
          FROM posts p
          JOIN categories c ON p.category_id = c.id
          WHERE p.user_uid = u.uid AND p.created_at >= NOW() - INTERVAL '365 days'
        ), 0) AS INTEGER) AS xp_year

      FROM users u
      LEFT JOIN tiers t ON u.current_tier_id = t.id
      WHERE u.uid = $1`,
      [userId]
    );

    const analytics = analyticsRes.rows[0] || {
      total_xp: 0,
      tier_name: 'Tier 1',
      xp_week: 0,
      xp_month: 0,
      xp_year: 0
    };

    analytics.daily_streak = await getUserDailyStreak(userId);

    // Fetch daily missions with user completions
    const missionsRes = await pool.query(
      `SELECT 
        m.id, 
        m.title, 
        m.description, 
        m.xp_reward, 
        m.tier_id,
        um.completed_at
      FROM missions m
      LEFT JOIN user_missions um ON m.id = um.mission_id AND um.user_uid = $1
      WHERE m.is_daily = true
      ORDER BY m.id`,
      [userId]
    );

    res.status(200).json({
      analytics,
      missions: missionsRes.rows
    });
  } catch (err) {
    console.error('GET /api/missions/daily error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 9. GET /api/missions/fixed
app.get('/api/missions/fixed', protect, async (req, res) => {
  try {
    const userId = req.userId;

    const missionsRes = await pool.query(
      `SELECT 
        m.id, 
        m.title, 
        m.description, 
        m.xp_reward, 
        um.completed_at
      FROM missions m
      LEFT JOIN user_missions um ON m.id = um.mission_id AND um.user_uid = $1
      WHERE m.is_daily = false
      ORDER BY m.id`,
      [userId]
    );

    const prereqsRes = await pool.query(
      `SELECT mission_id, prerequisite_mission_id FROM mission_prerequisites`
    );

    res.status(200).json({
      missions: missionsRes.rows,
      prerequisites: prereqsRes.rows
    });
  } catch (err) {
    console.error('GET /api/missions/fixed error:', err);
    res.status(500).json({ error: err.message });
  }
});

// --- INFRASTRUCTURE CONFIG ---
app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    const redisAlive = redisClient.isOpen;
    if (redisAlive) await redisClient.ping();
    res.json({ status: 'ok', postgres: true, redis: redisAlive ? true : 'skipped' });
  } catch (err) {
    res.status(503).json({ status: 'degraded', error: err.message });
  }
});

async function start() {
  await redisClient.safeConnect();

  // Ensure notifications table exists
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_uid UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
        sender_uid UUID REFERENCES users(uid) ON DELETE SET NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);
    console.log('[INIT] Verified or created notifications table.');
  } catch (err) {
    console.log('[INIT WARNING] notifications check skipped:', err.message);
  }

  // Ensure post_reports table exists
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS post_reports (
        id SERIAL PRIMARY KEY,
        reporter_uid UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
        post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
        reason TEXT NOT NULL,
        status VARCHAR(50) NOT NULL DEFAULT 'pending_review'
      )
    `);
    console.log('[INIT] Verified or created post_reports table.');
  } catch (err) {
    console.log('[INIT WARNING] post_reports check skipped:', err.message);
  }

  // Ensure post_downvotes table exists
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS post_downvotes (
        id SERIAL PRIMARY KEY,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(post_id, user_uid)
      )
    `);
    console.log('[INIT] Verified or created post_downvotes table.');
  } catch (err) {
    console.log('[INIT WARNING] post_downvotes check skipped:', err.message);
  }

  // Ensure comment_likes table exists
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS comment_likes (
        id SERIAL PRIMARY KEY,
        comment_id INTEGER REFERENCES post_comments(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(comment_id, user_uid)
      )
    `);
    console.log('[INIT] Verified or created comment_likes table.');
  } catch (err) {
    console.log('[INIT WARNING] comment_likes check skipped:', err.message);
  }

  // Ensure comment_downvotes table exists
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS comment_downvotes (
        id SERIAL PRIMARY KEY,
        comment_id INTEGER REFERENCES post_comments(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(comment_id, user_uid)
      )
    `);
    console.log('[INIT] Verified or created comment_downvotes table.');
  } catch (err) {
    console.log('[INIT WARNING] comment_downvotes check skipped:', err.message);
  }

  app.listen(PORT, () => console.log(`EcoEcho API running live on port ${PORT}`));
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});