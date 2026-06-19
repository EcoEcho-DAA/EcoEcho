const { Pool } = require('pg');
require('dotenv').config();

const projectRef = 'cgchzvlunkatpjvpuluz';
const databasePassword = process.env.DB_PASSWORD || 'echoeco1007';
const cloudRegion = 'ap-southeast-2';

const targetHosts = [
  `aws-1-${cloudRegion}.pooler.supabase.com`,
  `aws-0-${cloudRegion}.pooler.supabase.com`
];

let activePool = null;
let initPromise = null;

async function autoDiscoverCloudRoute() {
  for (const host of targetHosts) {
    console.log(`[PRODUCTION] Testing cloud proxy node: ${host}`);

    const testPool = new Pool({
      user: `postgres.${projectRef}`,
      host: host,
      database: 'postgres',
      password: databasePassword,
      port: 5432,
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 4000
    });

    try {
      await testPool.query('SELECT 1');
      console.log(`[PRODUCTION SUCCESS] Connected! Active routing slot verified on: ${host}`);
      activePool = testPool;
      return;
    } catch (err) {
      console.log(`Proxy node ${host} skipped: ${err.message}`);
      await testPool.end();
    }
  }

  console.error('[CRITICAL ERROR] All regional cloud infrastructure nodes rejected the credentials.');
  throw new Error('Please confirm that your Connection Pooler is ON in Supabase and your DB_PASSWORD is correct.');
}

initPromise = autoDiscoverCloudRoute();

module.exports = {
  query: async (text, params) => {
    if (!activePool) {
      await initPromise;
    }
    return activePool.query(text, params);
  },
  end: () => activePool && activePool.end()
};