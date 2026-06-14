const db = require('c:/Users/jo/EcoEcho/backend/src/config/db');

async function checkDb() {
  console.log('Waiting for active pool to connect...');
  await new Promise(resolve => setTimeout(resolve, 4000));
  
  try {
    const tables = await db.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    console.log('Tables in database:', tables.rows.map(r => r.table_name));

    const categories = await db.query('SELECT * FROM categories');
    console.log('Categories:', categories.rows);

    const missions = await db.query('SELECT * FROM missions');
    console.log('Missions:', missions.rows);

    const postColumns = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'posts'
    `);
    console.log('Posts columns:', postColumns.rows);

    const userColumns = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users'
    `);
    console.log('Users columns:', userColumns.rows);

  } catch (err) {
    console.error('Error querying DB:', err);
  } finally {
    db.end();
  }
}

checkDb();
