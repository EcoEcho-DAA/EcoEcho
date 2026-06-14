const pool = require('../config/db');
const redisClient = require('../config/redisClient');
const { heapSort } = require('../algorithms/heapSort');
const { hasProgressionPath } = require('../algorithms/dfs');

const LEADERBOARD_CACHE_KEY = 'leaderboard:top20';
const LEADERBOARD_CACHE_TTL_SECONDS = 60;

// get /api/leaderboard — top 20 by total_xp
async function getLeaderboard(_req, res) {
  try {
    const cached = await redisClient.get(LEADERBOARD_CACHE_KEY);
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    const { rows } = await pool.query(
      `SELECT uid as id, username, total_xp, city, province
       FROM users`
    );

    const sorted = heapSort(rows);
    const top20 = sorted.slice(0, 20);

    // need to cache this so it loads fast
    await redisClient.set(LEADERBOARD_CACHE_KEY, JSON.stringify(top20), {
      EX: LEADERBOARD_CACHE_TTL_SECONDS,
    });

    return res.json(top20);
  } catch (err) {
    console.error('getLeaderboard error:', err);
    return res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
}

// parent_tier_id -> [child ids] for dfs
function buildTierAdjacencyList(tiers) {
  const adjacencyList = {};

  for (const tier of tiers) {
    if (tier.parent_tier_id == null) {
      continue;
    }

    const parentId = tier.parent_tier_id;
    if (!adjacencyList[parentId]) {
      adjacencyList[parentId] = [];
    }
    adjacencyList[parentId].push(tier.id);
  }

  return adjacencyList;
}

// get /api/tiers/progression?currentTierId=&targetTierId=
async function checkTierProgression(req, res) {
  try {
    const currentTierId = Number(req.query.currentTierId);
    const targetTierId = Number(req.query.targetTierId);

    if (!Number.isInteger(currentTierId) || !Number.isInteger(targetTierId)) {
      return res.status(400).json({
        error: 'currentTierId and targetTierId must be valid integers',
      });
    }

    const { rows } = await pool.query(
      `SELECT id, parent_tier_id FROM tiers`
    );

    const adjacencyList = buildTierAdjacencyList(rows);
    const canProgress = hasProgressionPath(
      currentTierId,
      targetTierId,
      adjacencyList
    );

    return res.json({ canProgress });
  } catch (err) {
    console.error('checkTierProgression error:', err);
    return res.status(500).json({ error: 'Failed to check tier progression' });
  }
}

module.exports = { getLeaderboard, checkTierProgression };
