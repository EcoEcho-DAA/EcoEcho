const fs = require('fs');
const db = require('./src/config/db');

async function runSeed() {
  console.log('Waiting for db connection...');
  await new Promise(resolve => setTimeout(resolve, 3000));

  try {
    const seedSql = fs.readFileSync('./db/seed.sql', 'utf8');
    await db.query(seedSql);
    console.log('Seed successful');
  } catch (err) {
    console.error('Seed failed:', err);
  } finally {
    process.exit(0);
  }
}

runSeed();
