/**
 * Calculates the percentile rank for a position in a sorted ascending array.
 *
 * Time Complexity: O(1)
 * Space Complexity: O(1)
 *
 * @param {number} index - The index of the item.
 * @param {number} length - The total number of items in the array.
 * @returns {number} The percentile rank (value between 0 and 100).
 */
function percentileAtIndex(index, length) {
  if (length <= 0) {
    return 0;
  }
  if (length === 1) {
    return 100;
  }
  return Math.round((index / (length - 1)) * 1000) / 10;
}

/**
 * Searches for a target score in a sorted ascending array using a divide-and-conquer binary search.
 * If an exact match is found, returns its index and its percentile rank.
 * If an exact match is not found, cleanly falls back to finding the nearest logical score boundary
 * and computes the percentile rank of that boundary.
 *
 * Time Complexity: O(log n) where n is the length of the sortedScores array.
 * Space Complexity: O(1) auxiliary space.
 *
 * @param {number[]} sortedScores - An array of scores sorted in ascending order.
 * @param {number} targetScore - The target score to locate.
 * @returns {{index: number, percentileRank: number}} The result containing matching/fallback index and percentile rank.
 */
function binarySearch(sortedScores, targetScore) {
  if (!Array.isArray(sortedScores) || sortedScores.length === 0) {
    return { index: -1, percentileRank: 0 };
  }

  let left = 0;
  let right = sortedScores.length - 1;

  while (left <= right) {
    const mid = Math.floor((left + right) / 2);
    const midScore = sortedScores[mid];

    if (midScore === targetScore) {
      return {
        index: mid,
        percentileRank: percentileAtIndex(mid, sortedScores.length),
      };
    }

    if (midScore < targetScore) {
      left = mid + 1;
    } else {
      right = mid - 1;
    }
  }

  // no exact match — pick closest score for percentile
  const n = sortedScores.length;
  let nearestIndex = left;

  if (left >= n) {
    nearestIndex = n - 1;
  } else if (left > 0) {
    const distLeft = Math.abs(sortedScores[left - 1] - targetScore);
    const distRight = Math.abs(sortedScores[left] - targetScore);
    nearestIndex = distLeft <= distRight ? left - 1 : left;
  }

  return {
    index: -1,
    percentileRank: percentileAtIndex(nearestIndex, n),
  };
}

module.exports = { binarySearch };
