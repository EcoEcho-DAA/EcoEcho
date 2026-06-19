/**
 * precomputes the Longest Prefix Suffix (LPS) table for the Knuth-Morris-Pratt (KMP) algorithm.
 * it stores the lengths of the longest proper prefix of the pattern
 * that is also a suffix of the pattern's prefix.

 * pattern - The search pattern.
 * return number - computed LPS table.
 */
function buildLps(pattern) {
  const lps = Array(pattern.length).fill(0);
  let prefixLen = 0;
  let i = 1;

  while (i < pattern.length) {
    if (pattern[i] === pattern[prefixLen]) {
      prefixLen += 1;
      lps[i] = prefixLen;
      i += 1;
    } else if (prefixLen > 0) {
      prefixLen = lps[prefixLen - 1];
    } else {
      lps[i] = 0;
      i += 1;
    }
  }

  return lps;
}

/**
 * Searches for a pattern within a text using the Knuth-Morris-Pratt (KMP) algorithm.
 * Normalizes both text and pattern to lowercase to perform a case-insensitive search.
 * Does not use high-level library functions or built-in JavaScript array matching for the computation.
 *
 * Time Complexity: O(n + m) where n is the length of the text and m is the length of the pattern.
 * Space Complexity: O(m) auxiliary space for the LPS array.
 *
 * @param {string} text - The main text to search within.
 * @param {string} pattern - The substring pattern to look for.
 * @returns {boolean} True if the pattern is found within the text, false otherwise.
 */
function kmpContains(text, pattern) {
  const t = typeof text === 'string' ? text.toLowerCase() : '';
  const p = typeof pattern === 'string' ? pattern.toLowerCase() : '';

  if (!p.length) {
    return true;
  }
  if (!t.length) {
    return false;
  }

  const lps = buildLps(p);
  let i = 0;
  let j = 0;

  while (i < t.length) {
    if (t[i] === p[j]) {
      i += 1;
      j += 1;
      if (j === p.length) {
        return true;
      }
    } else if (j > 0) {
      j = lps[j - 1];
    } else {
      i += 1;
    }
  }

  return false;
}

/**
 * Normalizes a list entry (either a string or an object with username/uid/id)
 * to a single searchable text string.
 *
 * Time Complexity: O(1) auxiliary operations.
 * Space Complexity: O(1) auxiliary space.
 *
 * @param {string|object} entry - The entry to normalize.
 * @returns {string} The normalized searchable text.
 */
function entryToSearchText(entry) {
  if (typeof entry === 'string') {
    return entry;
  }
  if (entry && typeof entry === 'object') {
    const username = entry.username ?? '';
    const uid = entry.uid ?? entry.id ?? '';
    return `${username} ${uid}`.trim();
  }
  return '';
}

/**
 * Filters a list of buddy entries based on a search pattern using KMP matching.
 * The matching is case-insensitive.
 *
 * Time Complexity: O(N * (L + m)) where N is the number of entries, L is the average
 * length of an entry's searchable text, and m is the pattern length.
 * Space Complexity: O(m) auxiliary space for KMP plus O(N) space for the filtered result array.
 *
 * @param {Array<string|object>} entries - The list of user profiles or strings to filter.
 * @param {string} pattern - The search term pattern.
 * @returns {Array<string|object>} The filtered list of entries.
 */
function filterMatches(entries, pattern) {
  if (!Array.isArray(entries)) {
    return [];
  }
  if (!pattern || typeof pattern !== 'string') {
    return [...entries];
  }

  const needle = pattern.toLowerCase();

  return entries.filter((entry) => {
    const haystack = entryToSearchText(entry);
    return kmpContains(haystack, needle);
  });
}

module.exports = { filterMatches, kmpContains };
