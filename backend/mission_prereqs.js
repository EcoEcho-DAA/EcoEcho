require('dotenv').config();
const db = require('./src/config/db');

async function migrate() {
  console.log('Waiting for db connection...');
  await new Promise(resolve => setTimeout(resolve, 3000));

  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS mission_prerequisites (
        mission_id INTEGER REFERENCES missions(id) ON DELETE CASCADE,
        prerequisite_mission_id INTEGER REFERENCES missions(id) ON DELETE CASCADE,
        PRIMARY KEY (mission_id, prerequisite_mission_id)
      );
      
      -- Let's create a DAG for missions:
      -- Mission 2 (hydrosaver) requires Mission 1 (unplug installer) and Mission 3 (plastic purge)
      -- Mission 4 (plant a Tree) requires Mission 2 (hydrosaver)
      
      INSERT INTO mission_prerequisites (mission_id, prerequisite_mission_id)
      VALUES 
        (2, 1),
        (2, 3),
        (102, 101),
        (103, 101),
        (104, 102),
        (105, 103)
      ON CONFLICT DO NOTHING;
    `);
    console.log('Migration successful: Created mission_prerequisites table and dummy data.');
  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    // We shouldn't exit the whole process if others are using it, but since it's a standalone script:
    process.exit(0);
  }
}

migrate();
