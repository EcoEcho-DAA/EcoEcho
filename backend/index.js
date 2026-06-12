require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('./src/config/db');
const redisClient = require('./src/config/redisClient');
const { getWrappedDataForUser } = require('./src/controllers/wrappedQueriesController');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret';

app.use(cors());
app.use(express.json());

// --- AUTHENTICATION MIDDLEWARE ---
async function protect(req, res, next) {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, JWT_SECRET);
      // Stores the validated UUID (uid) into the request object
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

    // Matches your exact schema columns: uid, username, email, password_hash, total_xp, city, province
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
    console.error('💥 Registration SQL Error:', err.message);
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
      `SELECT p.id, u.username AS author_name, p.caption, p.image_url, p.created_at
       FROM posts p
       INNER JOIN users u ON p.user_uid = u.uid
       ORDER BY p.created_at DESC`
    );
    return res.status(200).json(rows);
  } catch (err) {
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
  app.listen(PORT, () => console.log(`EcoEcho API running live on port ${PORT}`));
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});