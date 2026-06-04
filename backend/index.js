require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./src/config/db');
const redisClient = require('./src/config/redisClient');
const {
  getLeaderboard,
  checkTierProgression,
} = require('./src/controllers/ecoController');
const authRoutes = require('./src/routes/authRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);

app.get('/api/leaderboard', getLeaderboard);
app.get('/api/tiers/progression', checkTierProgression);

app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    await redisClient.ping();
    res.json({ status: 'ok', postgres: true, redis: true });
  } catch (err) {
    res.status(503).json({ status: 'degraded', error: err.message });
  }
});

async function start() {
  await redisClient.connect();
  app.listen(PORT, () => {
    console.log(`EcoEcho API listening on port ${PORT}`);
  });
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
