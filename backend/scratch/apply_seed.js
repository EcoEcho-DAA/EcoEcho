const fs = require('fs');
const path = require('path');
const db = require('../src/config/db');

async function applySeed() {
  // Wait a moment for db connections to auto-discover regional routing
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  try {
    const seedPath = path.join(__dirname, '../db/seed.sql');
    const sql = fs.readFileSync(seedPath, 'utf8');
    
    console.log('Ensuring users table has first_name column...');
    await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name VARCHAR(255);`);
    
    console.log('Applying seed...');
    await db.query(sql);
    console.log('Seed applied successfully');
  } catch (err) {
    console.error('Error applying seed:', err);
  } finally {
    db.end();
  }
}

applySeed();
