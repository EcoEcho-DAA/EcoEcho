/**
 * Swaps two elements in an array.
 *
 * Time Complexity: O(1)
 * Space Complexity: O(1)
 *
 * @param {Array} arr - The target array.
 * @param {number} i - Index of the first element.
 * @param {number} j - Index of the second element.
 */
function swap(arr, i, j) {
  const temp = arr[i];
  arr[i] = arr[j];
  arr[j] = temp;
}

/**
 * Restores the max-heap property at a given index, ordering objects by `total_xp`.
 *
 * Time Complexity: O(log N) where N is the heapSize.
 * Space Complexity: O(log N) due to recursive call stack.
 *
 * @param {Array} arr - The array representing the heap.
 * @param {number} heapSize - The size of the active heap.
 * @param {number} i - The root index of the subtree to heapify.
 */
function heapify(arr, heapSize, i) {
  let largest = i;
  const left = 2 * i + 1;
  const right = 2 * i + 2;

  if (left < heapSize && arr[left].total_xp > arr[largest].total_xp) {
    largest = left;
  }
  if (right < heapSize && arr[right].total_xp > arr[largest].total_xp) {
    largest = right;
  }

  if (largest !== i) {
    swap(arr, i, largest);
    heapify(arr, heapSize, largest);
  }
}

/**
 * Converts an unordered array into a max-heap.
 *
 * Time Complexity: O(N) where N is the length of the array.
 * Space Complexity: O(log N) recursive call stack depth from heapify.
 *
 * @param {Array} arr - The array to build the max-heap from.
 */
function buildMaxHeap(arr) {
  const n = arr.length;
  for (let i = Math.floor(n / 2) - 1; i >= 0; i -= 1) {
    heapify(arr, n, i);
  }
}

/**
 * Sorts users in descending order of their total_xp using the Heap Sort algorithm.
 *
 * Time Complexity: O(N log N) where N is the number of user profiles.
 * Space Complexity: O(N) to store a copy of the users array.
 *
 * @param {Array} users - The array of user profiles to sort.
 * @returns {Array} A new array sorted in descending order of total_xp.
 */
function heapSort(users) {
  if (!Array.isArray(users) || users.length <= 1) {
    return Array.isArray(users) ? [...users] : [];
  }

  const arr = users.map((user) => ({ ...user }));
  const n = arr.length;

  buildMaxHeap(arr);

  for (let end = n - 1; end > 0; end -= 1) {
    swap(arr, 0, end);
    heapify(arr, end, 0);
  }

  // Heap sort leaves the array sorted in ascending order.
  // We reverse it to return it in descending order for the leaderboard.
  return arr.reverse();
}

/**
 * Wrapper method to recalculate global standings using heap sort.
 *
 * Time Complexity: O(N log N) where N is the number of user profiles.
 * Space Complexity: O(N) to store the copy of the users array.
 *
 * @param {Array} users - The array of user profiles to sort.
 * @returns {Array} A new array sorted in descending order of total_xp.
 */
function runLeaderboardHeapSort(users) {
  return heapSort(users);
}

module.exports = { heapSort, runLeaderboardHeapSort };
