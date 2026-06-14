const db = require('c:/Users/jo/EcoEcho/backend/src/config/db');

async function applyUpdates() {
  console.log('Waiting for active pool to connect...');
  await new Promise(resolve => setTimeout(resolve, 4000));

  try {
    console.log('Altering posts table...');
    await db.query(`
      ALTER TABLE posts 
      ADD COLUMN IF NOT EXISTS mission_id INTEGER REFERENCES missions(id) ON DELETE SET NULL;
    `);
    console.log('Posts table altered successfully.');

    console.log('Altering users table...');
    await db.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS profile_pic_url TEXT;
    `);
    console.log('Users table altered successfully.');

    // Print columns to verify
    const postColumns = await db.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'posts'
    `);
    console.log('Updated Posts columns:', postColumns.rows.map(r => r.column_name));

    const userColumns = await db.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users'
    `);
    console.log('Updated Users columns:', userColumns.rows.map(r => r.column_name));

  } catch (err) {
    console.error('Error applying schema updates:', err);
  } finally {
    db.end();
  }
}

applyUpdates();
