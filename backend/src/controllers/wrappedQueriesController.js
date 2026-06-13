const pool = require('../config/db');

async function getWrappedDataForUser(userId) {
  const query = `
    WITH user_base AS (
      SELECT u.total_xp, t.tier_name
      FROM users u
      LEFT JOIN tiers t ON t.id = u.current_tier_id
      WHERE u.uid = $1
    ),
    user_trees AS (
      SELECT COUNT(*)::int AS tree_count
      FROM user_missions
      WHERE user_uid = $1 -- ⚙️ FIXED: Changed from user_id to user_uid
        AND mission_id = 4
        AND EXTRACT(YEAR FROM completed_at) = EXTRACT(YEAR FROM NOW())
    ),
    user_posts AS (
      SELECT COUNT(*)::int AS post_count
      FROM posts
      WHERE user_uid = $1
        AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW())
    )

    SELECT
      100                                  AS ranking,
      (SELECT post_count FROM user_posts)  AS post_count,
      (SELECT tree_count FROM user_trees)  AS tree_count,
      (SELECT tier_name  FROM user_base)   AS tier_name,
      (SELECT total_xp   FROM user_base)   AS total_xp
  `;

  const { rows } = await pool.query(query, [userId]);

  if (rows.length === 0) return null;

  const row = rows[0];
  return {
    ranking: row.ranking,
    post_count: row.post_count,
    tree_count: row.tree_count,
    tier_name: row.tier_name ?? 'Seed',
    total_xp: row.total_xp ?? 0,
  };
}

module.exports = { getWrappedDataForUser };