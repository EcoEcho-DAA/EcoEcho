/* const { createClient } = require('redis');

const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: Number(process.env.REDIS_PORT) || 6379,
  },
});

redisClient.on('error', (err) => {
  console.error('Redis client error:', err);
});

module.exports = redisClient; */

const { createClient } = require('redis');

const redisClient = createClient({
  url: process.env.redis_url,
});

redisClient.on('error', (err) => {
  console.error('Redis client error:', err);
});

module.exports = redisClient; 