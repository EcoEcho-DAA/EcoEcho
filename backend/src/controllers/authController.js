const crypto = require('crypto');
const pool = require('../config/db');
const { binarySearch } = require('../algorithms/binarySearch');

const ENV_BENCHMARKS = [100, 300, 500, 800, 1200, 2000, 3000];

// hash password with scrypt + random salt
function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

// constant-time compare for login
function verifyPassword(password, storedHash) {
  const [salt, expectedHash] = storedHash.split(':');
  if (!salt || !expectedHash) {
    return false;
  }
  const actualHash = crypto.scryptSync(password, salt, 64).toString('hex');
  const expected = Buffer.from(expectedHash, 'hex');
  const actual = Buffer.from(actualHash, 'hex');
  if (expected.length !== actual.length) {
    return false;
  }
  return crypto.timingSafeEqual(expected, actual);
}

// map percentile rank to a tier row from db
async function tierIdFromPercentileRank(percentileRank) {
  const { rows } = await pool.query(
    `SELECT id, required_xp FROM tiers ORDER BY required_xp ASC`
  );

  if (rows.length === 0) {
    return null;
  }

  const slot = Math.min(
    rows.length - 1,
    Math.floor((percentileRank / 100) * rows.length)
  );

  return rows[slot].id;
}

// post /signup
async function signup(req, res) {
  try {
    const { username, email, password, ecoScore } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: 'username, email, and password are required' });
    }

    // Force default environmental score/total_xp to start at exactly 0
    const percentileRank = 0;
    const currentTierId = 1; // baseline Tier 1

    const passwordHash = hashPassword(password);
    const totalXp = 0;

    const { rows } = await pool.query(
      `INSERT INTO users (username, email, password_hash, total_xp, current_tier_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING uid, username, email, total_xp, city, province, current_tier_id`,
      [username, email, passwordHash, totalXp, currentTierId]
    );

    const createdUser = rows[0];

    // Log the user registration activity in activity_logs
    try {
      await pool.query(
        `INSERT INTO activity_logs (user_uid, action_description) VALUES ($1, $2)`,
        [createdUser.uid, 'Registered user account via controller signup.']
      );
    } catch (logErr) {
      console.error('Error logging controller registration activity:', logErr.message);
    }

    return res.status(201).json({
      message: 'signup successful',
      percentileRank,
      user: createdUser,
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'email or username already exists' });
    }
    console.error('Detailed DB Error:', err);
    return res.status(500).json({ error: 'failed to create user' });
  }
}

// post /login
async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }

    const { rows } = await pool.query(
      `SELECT id, username, email, password_hash, total_xp, city, province, current_tier_id
       FROM users
       WHERE email = $1`,
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'invalid email or password' });
    }

    const user = rows[0];

    if (!verifyPassword(password, user.password_hash)) {
      return res.status(401).json({ error: 'invalid email or password' });
    }

    delete user.password_hash;

    return res.json({
      message: 'login successful',
      user,
    });
  } catch (err) {
    console.error('login error:', err);
    return res.status(500).json({ error: 'failed to log in' });
  }
}

module.exports = { signup, login };
