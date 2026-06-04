const { createClient } = require('redis');

let redisConfig = {};

if (process.env.REDIS_URL) {
  let url = process.env.REDIS_URL;

  // If it's an Upstash cloud instance, ensure it uses the secure rediss:// protocol
  if (url.includes('upstash.io')) {
    if (url.startsWith('redis://')) {
      url = url.replace('redis://', 'rediss://');
    }

    redisConfig.url = url;
    redisConfig.socket = {
      tls: true,
      rejectUnauthorized: false
    };
  } else {
    redisConfig.url = url;
  }
} else {
  redisConfig.socket = {
    host: process.env.REDIS_HOST || 'localhost',
    port: Number(process.env.REDIS_PORT) || 6379,
  };
}

const redisClient = createClient(redisConfig);

// Configure your existing reconnect logic on the client
redisClient.options = {
  ...redisClient.options,
  reconnectStrategy: (retries) => {
    if (process.env.NODE_ENV === 'production' || process.env.DATABASE_URL) {
      if (retries > 3) {
        console.warn(' Giving up on Redis connection to let Express server bind to port.');
        return new Error('Redis connection timed out');
      }
    }
    return Math.min(retries * 100, 3000);
  }
};

// Intercept the error event cleanly so it does not trigger an unhandled exception crash
redisClient.on('error', (err) => {
  console.warn(' Redis Connection Error handled gracefully:', err.message);
});

// Helper function to safely connect without crashing the app startup process
redisClient.safeConnect = async () => {
  try {
    await Promise.race([
      redisClient.connect(),
      new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 4000))
    ]);
    console.log(' Redis cache online.');
  } catch (err) {
    console.warn(' Skipping Redis initialization loop. Backend will query Supabase directly.');
  }
};

module.exports = redisClient;