const db = require('c:/Users/jo/EcoEcho/backend/src/config/db');

async function applyUpdates() {
  console.log('Waiting for active pool to connect...');
  await new Promise(resolve => setTimeout(resolve, 4000));

  try {
    console.log('Altering users table...');
    await db.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS bio TEXT;
    `);
    console.log('Users table altered successfully.');

    console.log('Creating user_reports table...');
    await db.query(`
      CREATE TABLE IF NOT EXISTS user_reports (
        id SERIAL PRIMARY KEY,
        target_user_uid UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
        reporter_uid UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
        reason TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('user_reports table created successfully.');

    // Print columns to verify
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
