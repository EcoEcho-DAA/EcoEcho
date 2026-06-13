// Master DAG dictionary template representing the platform's gamified milestones.
// Keys are mission IDs, and values are arrays of prerequisite mission IDs.
const MISSION_DAG = {
  1: [],        // Mission 1: no prerequisites
  2: [1],       // Mission 2: requires Mission 1
  3: [1],       // Mission 3: requires Mission 1
  4: [2, 3]     // Mission 4: requires Mission 2 and Mission 3
};

/**
 * Helper to retrieve neighbors from the adjacency list.
 *
 * Time Complexity: O(1)
 * Space Complexity: O(1)
 *
 * @param {number|string} tierId - The active tier ID.
 * @param {Object} adjacencyList - The tier adjacency list.
 * @returns {number[]} Array of child tier IDs.
 */
function getNeighbors(tierId, adjacencyList) {
  if (tierId in adjacencyList) {
    return adjacencyList[tierId];
  }
  const key = String(tierId);
  return adjacencyList[key] ?? [];
}

/**
 * Checks if a target tier is reachable from a current tier using DFS.
 * Used for checking progression paths between tiers.
 *
 * Time Complexity: O(V + E) where V is the number of tiers and E is the number of parent-child relationships.
 * Space Complexity: O(V) auxiliary space for the visited Set and the recursive call stack.
 *
 * @param {number} currentTierId - The starting tier.
 * @param {number} targetTierId - The destination tier.
 * @param {Object} adjacencyList - Adjacency mapping of tiers.
 * @returns {boolean} True if reachable, false otherwise.
 */
function hasProgressionPath(currentTierId, targetTierId, adjacencyList) {
  if (currentTierId === targetTierId) {
    return true;
  }

  if (!adjacencyList || typeof adjacencyList !== 'object') {
    return false;
  }

  const visited = new Set();

  function dfs(node) {
    if (node === targetTierId || String(node) === String(targetTierId)) {
      return true;
    }

    const visitKey = String(node);
    if (visited.has(visitKey)) {
      return false;
    }
    visited.add(visitKey);

    for (const neighbor of getNeighbors(node, adjacencyList)) {
      if (dfs(neighbor)) {
        return true;
      }
    }

    return false;
  }

  return dfs(currentTierId);
}

/**
 * Recursively verifies if all prerequisite missions for a target mission have been completed.
 * Uses Depth-First Search (DFS) to traverse the Directed Acyclic Graph (DAG) of prerequisites.
 *
 * Time Complexity: O(V + E) where V is the number of unique prerequisite missions in the subtree,
 *                  and E is the number of prerequisite dependency edges in the subtree.
 * Space Complexity: O(V) auxiliary space to store the completion lookup set, path tracking set,
 *                  and the recursion call stack.
 *
 * @param {number} targetMissionId - The ID of the mission to verify.
 * @param {number[]} completedMissionIds - Array of mission IDs the user has already completed.
 * @returns {boolean} True if all nested prerequisites are completed, false otherwise.
 */
function verifyMissionPrerequisites(targetMissionId, completedMissionIds) {
  const completedSet = new Set(completedMissionIds.map(Number));
  const path = new Set();

  function dfsCheck(node) {
    // Avoid cycles in the graph (in case of malformed templates)
    if (path.has(node)) {
      return false;
    }
    path.add(node);

    // Retrieve direct prerequisites
    const prerequisites = MISSION_DAG[node] ?? [];

    for (const prereq of prerequisites) {
      const prereqNum = Number(prereq);
      // The prerequisite mission itself must have been completed
      if (!completedSet.has(prereqNum)) {
        return false;
      }
      // Recursively check all prerequisites of the prerequisite mission
      if (!dfsCheck(prereqNum)) {
        return false;
      }
    }

    path.delete(node);
    return true;
  }

  return dfsCheck(Number(targetMissionId));
}

module.exports = {
  hasProgressionPath,
  verifyMissionPrerequisites,
  MISSION_DAG
};
