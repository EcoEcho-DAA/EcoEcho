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
const { verifyMissionPrerequisites } = require('./src/algorithms/dfs');
const supabase = require('./src/config/supabaseClient');

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

// --- DYNAMIC ROUTES ---

// 1. REGISTER A NEW USER
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

    const newUser = await pool.query(
      `INSERT INTO users (username, email, password_hash, total_xp, city, province) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       RETURNING uid, username, email, total_xp`,
      [
        finalUsername,
        email,
        passwordHash,
        environmentalScore || 100,
        city || 'Manila',
        province || 'Metro Manila'
      ]
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully in the cloud!',
      user: newUser.rows[0]
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
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
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

    res.json({
      token,
      user: {
        uid: user.uid,
        username: user.username,
        email: user.email,
        total_xp: user.total_xp
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
      `SELECT u.uid, u.username, u.email, u.total_xp, u.city, u.province, t.tier_name 
       FROM users u 
       LEFT JOIN tiers t ON u.current_tier_id = t.id 
       WHERE u.uid = $1`,
      [req.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'User profile not found' });
    }

    return res.status(200).json(userResult.rows[0]);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// --- DYNAMIC ROUTES (CONTINUED) ---

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

// 5. GET LEADERBOARD OF TOP USERS
app.get('/api/users/leaderboard', async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT u.uid, u.username, u.total_xp, u.city, u.province, t.tier_name
       FROM users u
       INNER JOIN tiers t ON u.current_tier_id = t.id
       ORDER BY u.total_xp DESC
       LIMIT 10`
    );
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

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

// 7. GET /api/feed/trending -> Satisfies the community social impact feed
app.get('/api/feed/trending', async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.id, u.username AS author_name, p.caption, p.image_url, p.created_at, c.name as tag_text
       FROM posts p
       INNER JOIN users u ON p.user_uid = u.uid
       LEFT JOIN categories c ON p.category_id = c.id
       ORDER BY p.created_at DESC`
    );
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// 7b. POST /api/posts -> Creates a new post 
const FLAGGED_TERMS = ['badword1', 'spamlink', 'toxicphrase'];
app.post('/api/posts', protect, upload.single('image'), async (req, res) => {
  const { caption, category_id } = req.body;
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

        // Upload file buffer directly to Supabase Storage
        const { data, error } = await supabase.storage
          .from(bucketName)
          .upload(filename, req.file.buffer, {
            contentType: req.file.mimetype,
            upsert: false
          });

        if (error) {
          throw new Error(`Supabase storage error: ${error.message}`);
        }

        // Retrieve the public URL
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

    const newPost = await pool.query(
      `INSERT INTO posts (user_uid, caption, category_id, image_url)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.userId, textToCheck, category_id || null, image_url]
    );

    await pool.query(
      `UPDATE users SET total_xp = total_xp + 50 WHERE uid = $1`,
      [req.userId]
    );

    res.status(201).json({
      success: true,
      message: 'Post created successfully!',
      post: newPost.rows[0]
    });
  } catch (err) {
    console.error('POST /api/posts error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 7c. GET /api/users/me/posts
app.get('/api/users/me/posts', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.id, u.username AS author_name, p.caption, p.image_url, p.created_at, c.name as tag_text
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

// 8. GET /api/missions/daily
app.get('/api/missions/daily', protect, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, title, description, xp_reward, tier_id FROM missions WHERE is_daily = true'
    );
    return res.status(200).json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});



// --- POST /api/posts/:id/vote (Relational Voting & Leaderboard) ---
app.post('/api/posts/:id/vote', protect, async (req, res) => {
  const postId = Number(req.params.id);
  const { vote_direction } = req.body;

  if (isNaN(postId)) {
    return res.status(400).json({ error: 'Invalid post ID' });
  }

  if (vote_direction !== 'up' && vote_direction !== 'down') {
    return res.status(400).json({ error: "vote_direction must be 'up' or 'down'" });
  }

  try {
    // 1. Find the author (user_uid) of the target post ID
    const postResult = await pool.query('SELECT user_uid FROM posts WHERE id = $1', [postId]);
    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const authorUid = postResult.rows[0].user_uid;
    const change = vote_direction === 'up' ? 10 : -5;

    // 2. Transactional database update: modify total_xp of author (ensuring it stays >= 0)
    await pool.query(
      `UPDATE users SET total_xp = GREATEST(0, total_xp + $1) WHERE uid = $2`,
      [change, authorUid]
    );

    // 3. Immediately query users for uid and total_xp
    const usersResult = await pool.query('SELECT uid, total_xp FROM users');

    // 4. Recalculate standings using heap sort
    const sortedStandings = runLeaderboardHeapSort(usersResult.rows);

    // 5. Return updated root node of sorted heap (highest ranked user)
    const rootNode = sortedStandings.length > 0 ? sortedStandings[0] : null;

    return res.status(200).json(rootNode);
  } catch (err) {
    console.error('Error voting on post:', err);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// --- NEW ROUTE: POST /api/reports/submit (Social Safety Reporting System) ---
app.post('/api/reports/submit', protect, async (req, res) => {
  const { post_id, reason } = req.body;

  if (!post_id || !reason) {
    return res.status(400).json({ error: 'post_id and reason are required' });
  }

  try {
    const result = await pool.query(
      `INSERT INTO post_reports (reporter_uid, post_id, reason, status)
       VALUES ($1, $2, $3, 'pending_review')
       RETURNING id, reporter_uid, post_id, reason, status`,
      [req.userId, post_id, reason]
    );

    return res.status(201).json({
      success: true,
      message: 'Report submitted successfully.',
      report: result.rows[0]
    });
  } catch (err) {
    console.error('Error submitting report:', err);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// --- NEW ROUTE: POST /api/posts/verify-mission (User Mission Verification) ---
app.post('/api/posts/verify-mission', protect, async (req, res) => {
  const targetMissionId = Number(req.body.target_mission_id);
  const userId = req.userId;

  if (isNaN(targetMissionId)) {
    return res.status(400).json({ error: 'target_mission_id must be a valid number' });
  }

  try {
    // 1. Database Context Retrieval: Pull completed missions for this user
    const completedResult = await pool.query(
      `SELECT mission_id FROM user_missions WHERE user_uid = $1`,
      [userId]
    );

    // Map database result into a flat array of completed task integers
    const completedMissionIds = completedResult.rows.map(row => Number(row.mission_id));

    // 2. Algorithmic DFS Traversal: Check prerequisites recursively
    const isEligible = verifyMissionPrerequisites(targetMissionId, completedMissionIds);

    if (!isEligible) {
      // Return 403 Forbidden if prerequisites are missing
      return res.status(403).json({
        status: "Progression Denied",
        message: "Prerequisite structural tasks for this tier branch are incomplete."
      });
    }

    // 3. State Enforcement Action: Log mission completion
    await pool.query(
      `INSERT INTO user_missions (user_uid, mission_id, completed_at)
       VALUES ($1, $2, NOW())
       ON CONFLICT (user_uid, mission_id) DO NOTHING`,
      [userId, targetMissionId]
    );

    return res.status(200).json({
      success: true,
      message: "Mission verification successful. Prerequisite verification passed and mission progress recorded."
    });
  } catch (err) {
    console.error('Error verifying mission:', err);
    return res.status(500).json({ error: 'Internal Server Error' });
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

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`EcoEcho API running live on port ${PORT}`);
  });
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});