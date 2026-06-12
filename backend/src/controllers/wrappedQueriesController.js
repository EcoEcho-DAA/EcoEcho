const pool = require('../config/db');

async function getWrappedDataForUser(userId) {
  const query = `
  WITH user_base AS (
    SELECT u.total_xp, t.tier_name
    FROM users u
    LEFT JOIN tiers t ON t.id = u.current_tier_id
    WHERE u.id = $1
  ),
  user_trees AS (
    SELECT COUNT(*)::int AS tree_count
    FROM user_missions
    WHERE user_id = $1
      AND mission_id = 4
      AND EXTRACT(YEAR FROM completed_at) = EXTRACT(YEAR FROM NOW())
  )

  SELECT
    100                                  AS ranking,
    0                                    AS post_count,
    (SELECT tree_count FROM user_trees)  AS tree_count,
    (SELECT tier_name  FROM user_base)   AS tier_name,
    (SELECT total_xp   FROM user_base)   AS total_xp
`;

  const { rows } = await pool.query(query, [userId]);

  if (rows.length === 0) return null;

  const row = rows[0];
  return {
    ranking:    row.ranking,
    post_count: row.post_count,
    tree_count: row.tree_count,
    tier_name:  row.tier_name,
    total_xp:   row.total_xp,
  };
}

module.exports = { getWrappedDataForUser };

/*  
    population_index AS (
      SELECT
        id AS user_id,
        GREATEST(
          1,
          CEIL(100.0 * PERCENT_RANK() OVER (ORDER BY total_xp DESC))::int
        ) AS percentile_rank
      FROM users
      WHERE id IN (
        SELECT DISTINCT user_id
        FROM posts
        WHERE EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW())
      )
    ) 
      
    SELECT
      COALESCE(
      (SELECT percentile_rank FROM population_index WHERE user_id = $1),
      100
      ) AS ranking,    
      (SELECT post_count  FROM user_posts) AS post_count,
      */