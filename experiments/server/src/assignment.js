const fs = require('fs').promises;
const path = require('path');

const cacheFilePath = path.join(__dirname, 'fileCache.json');
const filePath = path.join(__dirname, 'count.json');

// Function to increment the count in the JSON file
async function incrementCount() {
  try {
    const data = await fs.readFile(filePath, 'utf8');
    const jsonData = JSON.parse(data);
    jsonData.count += 1;
    await fs.writeFile(filePath, JSON.stringify(jsonData, null, 2), 'utf8');
    console.log('Count incremented successfully! New count:', jsonData.count);
    return jsonData.count;
  } catch (err) {
    console.error('Error incrementing count:', err);
    throw err;
  }
}

// Function to read the count from the JSON file
async function readCount() {
  try {
    const data = await fs.readFile(filePath, 'utf8');
    const jsonData = JSON.parse(data);
    return jsonData.count;
  } catch (err) {
    console.error('Error reading or parsing file:', err);
    throw err;
  }
}

// Function to check if the cache file exists
async function checkCacheFile() {
  try {
    await fs.access(cacheFilePath);
    return true;
  } catch {
    return false;
  }
}

// Load cache from file if it exists
async function loadCache() {
  try {
    const exists = await checkCacheFile();
    if (exists) {
      const data = await fs.readFile(cacheFilePath, 'utf8');
      return JSON.parse(data);
    }
    return [];
  } catch (err) {
    console.error('Error loading cache:', err);
    throw err;
  }
}

// Initialize cache
let cache = [];
loadCache()
  .then(data => {
    cache = data;
  })
  .catch(err => {
    console.error('Error initializing cache:', err);
  });

// Function to get a specific file based on the count
async function getNextGame() {
    try {
        let count = await readCount();
        let increment = true;
        if (count >= 7) {
            const data = await fs.readFile(filePath, 'utf8');
            const jsonData = JSON.parse(data);
            jsonData.count = 0;
            await fs.writeFile(filePath, JSON.stringify(jsonData, null, 2), 'utf8');
            throw new Error('Count exceeds the number of available files.');
        }

        const file = {
            count_no: count,
        };
        if (increment){
          await incrementCount();
        }
        return file;
    } catch (error) {
        console.error(`Error fetching file: ${error.message}`);
        throw error;
    }
}

module.exports = {
    getNextGame
};
