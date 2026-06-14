const pool = require('../config/db');
const { binarySearch } = require('../algorithms/binarySearch');

/**
 * Retrieves the EcoWrap summary data for a specific user, calculating their dynamic
 * performance ranking using a binary search over the global population scores, and
 * aggregating their posts and tree planting missions directly from database tables.
 *
 * Time Complexity:
 *   - Database query for scores: O(N log N) inside Postgres for sorting, and O(N) map in Node.js.
 *   - User profile query and aggregations: O(log M + log P) where M is the number of user missions
 *     and P is the number of posts (using indexes).
 *   - Binary Search: O(log N) where N is the total number of users.
 *   Total time complexity: O(N) for Node.js array mapping, dominated by SQL database operations.
 *
 * Space Complexity:
 *   - O(N) auxiliary space in memory to hold the flat scores array of all users.
 *
 * @param {string} userId - The authenticated user's uid (UUID).
 * @returns {Promise<Object|null>} The formatted EcoWrap payload, or null if user not found.
 */
async function getWrappedDataForUser(userId) {
  // 1. Target Profile Evaluation: Fetch current user's total_xp and tier_name
  const userResult = await pool.query(
    `SELECT u.total_xp, t.tier_name 
     FROM users u
     LEFT JOIN tiers t ON u.current_tier_id = t.id
     WHERE u.uid = $1`,
    [userId]
  );

  if (userResult.rows.length === 0) {
    return null;
  }

  const currentUser = userResult.rows[0];
  const totalXp = Number(currentUser.total_xp ?? 0);
  const tierName = currentUser.tier_name ?? 'Seed';

  // 2. Population Score Extraction: Retrieve and sort total_xp for all registered users
  const allScoresResult = await pool.query(
    `SELECT total_xp FROM users ORDER BY total_xp ASC`
  );
  const sortedScores = allScoresResult.rows.map(row => Number(row.total_xp));

  // 3. Binary Search & Percentile Mapping: Place user score on global distribution
  const { percentileRank } = binarySearch(sortedScores, totalXp);
  const ranking = Math.max(1, Math.round(100 - percentileRank));

  // 4. Relational Table Aggregations: Count actual posts by user
  const postsResult = await pool.query(
    `SELECT COUNT(*)::int AS post_count FROM posts WHERE user_uid = $1`,
    [userId]
  );
  const postCount = postsResult.rows[0].post_count ?? 0;

  // Count actual tree planting missions completed by user (mission_id = 4)
  const treesResult = await pool.query(
    `SELECT COUNT(*)::int AS tree_count 
     FROM user_missions 
     WHERE user_uid = $1 AND mission_id = 4`,
    [userId]
  );
  const treeCount = treesResult.rows[0].tree_count ?? 0;

  // 5. Payload Formatting Validation: Return the structured properties for Flutter frontend
  return {
    ranking: ranking,
    post_count: postCount,
    tree_count: treeCount,
    tier_name: tierName,
    total_xp: totalXp
  };
}

module.exports = { getWrappedDataForUser };