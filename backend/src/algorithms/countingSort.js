// pull category tag from a log row
function getCategoryTag(log) {
  return log.category ?? log.category_id ?? log.categoryTag;
}

// counting sort by tag frequency — for sustainability analytics
function countingSort(logs) {
  if (!Array.isArray(logs) || logs.length === 0) {
    return [];
  }

  const frequencyByTag = new Map();

  for (const log of logs) {
    const tag = getCategoryTag(log);
    if (tag === undefined || tag === null) {
      continue;
    }
    frequencyByTag.set(tag, (frequencyByTag.get(tag) ?? 0) + 1);
  }

  if (frequencyByTag.size === 0) {
    return [];
  }

  let maxFrequency = 0;
  for (const count of frequencyByTag.values()) {
    if (count > maxFrequency) {
      maxFrequency = count;
    }
  }

  // frequency array lookup — bucket tags by how often they appear
  const buckets = Array.from({ length: maxFrequency + 1 }, () => []);

  for (const [tag, count] of frequencyByTag.entries()) {
    buckets[count].push(tag);
  }

  const sortedByFrequency = [];

  for (let freq = maxFrequency; freq >= 1; freq -= 1) {
    for (const tag of buckets[freq]) {
      sortedByFrequency.push({ category: tag, frequency: freq });
    }
  }

  return sortedByFrequency;
}

// Generic counting sort for numeric keys – used for popularity sorting of feeds
function countingSortByKey(arr, keyFn) {
  if (!Array.isArray(arr) || arr.length === 0) return [];
  // Determine min and max key values
  let min = Infinity, max = -Infinity;
  for (const item of arr) {
    const k = keyFn(item);
    if (typeof k !== 'number' || isNaN(k)) continue;
    if (k < min) min = k;
    if (k > max) max = k;
  }
  if (min === Infinity) return [];
  const range = max - min + 1;
  const buckets = Array.from({ length: range }, () => []);
  for (const item of arr) {
    const k = keyFn(item);
    if (typeof k !== 'number' || isNaN(k)) continue;
    buckets[k - min].push(item);
  }
  // Concatenate buckets in descending order (most popular first)
  const sorted = [];
  for (let i = range - 1; i >= 0; i--) {
    if (buckets[i].length) sorted.push(...buckets[i]);
  }
  return sorted;
}

module.exports = { countingSort, countingSortByKey };
