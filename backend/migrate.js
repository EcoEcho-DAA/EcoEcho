require('dotenv').config();
const db = require('./src/config/db');

async function migrate() {
  console.log('Waiting for db connection...');
  await new Promise(resolve => setTimeout(resolve, 3000));

  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS post_likes (
        id SERIAL PRIMARY KEY,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(post_id, user_uid)
      );

      CREATE TABLE IF NOT EXISTS post_comments (
        id SERIAL PRIMARY KEY,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS post_downvotes (
        id SERIAL PRIMARY KEY,
        post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(post_id, user_uid)
      );

      CREATE TABLE IF NOT EXISTS comment_likes (
        id SERIAL PRIMARY KEY,
        comment_id INTEGER REFERENCES post_comments(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(comment_id, user_uid)
      );

      CREATE TABLE IF NOT EXISTS comment_downvotes (
        id SERIAL PRIMARY KEY,
        comment_id INTEGER REFERENCES post_comments(id) ON DELETE CASCADE,
        user_uid UUID REFERENCES users(uid) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(comment_id, user_uid)
      );
    `);
    console.log('Migration successful');
  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    db.end();
  }
}

migrate();
