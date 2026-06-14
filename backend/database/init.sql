-- ecoecho schema init
-- run on ecoecho_db (see docker-compose :) )

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- tier tree for progression dfs
CREATE TABLE IF NOT EXISTS tiers (
    id              SERIAL PRIMARY KEY,
    tier_name       VARCHAR(100) NOT NULL UNIQUE,
    required_xp     INTEGER NOT NULL DEFAULT 0 CHECK (required_xp >= 0)
);

CREATE TABLE IF NOT EXISTS tier_prerequisites (
    tier_id              INTEGER REFERENCES tiers (id) ON DELETE CASCADE,
    prerequisite_tier_id INTEGER REFERENCES tiers (id) ON DELETE CASCADE,
    PRIMARY KEY (tier_id, prerequisite_tier_id)
);

-- users
CREATE TABLE IF NOT EXISTS users (
    uid              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username         VARCHAR(50) NOT NULL UNIQUE,
    email            VARCHAR(255) NOT NULL UNIQUE,
    password_hash    VARCHAR(255) NOT NULL,
    first_name       VARCHAR(255),
    total_xp         INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
    city             VARCHAR(100),
    province         VARCHAR(100),
    current_tier_id  INTEGER REFERENCES tiers (id) ON DELETE SET NULL
);

-- categories
CREATE TABLE IF NOT EXISTS categories (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    xp_weight   INTEGER NOT NULL DEFAULT 10
);

-- posts
CREATE TABLE IF NOT EXISTS posts (
    id          SERIAL PRIMARY KEY,
    user_uid    UUID NOT NULL REFERENCES users (uid) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories (id) ON DELETE SET NULL,
    image_url   TEXT,
    caption     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- likes
CREATE TABLE IF NOT EXISTS likes (
    id          SERIAL PRIMARY KEY,
    user_uid    UUID NOT NULL REFERENCES users (uid) ON DELETE CASCADE,
    post_id     INTEGER NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    UNIQUE(user_uid, post_id)
);

-- comments
CREATE TABLE IF NOT EXISTS comments (
    id          SERIAL PRIMARY KEY,
    user_uid    UUID NOT NULL REFERENCES users (uid) ON DELETE CASCADE,
    post_id     INTEGER NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- missions
CREATE TABLE IF NOT EXISTS missions (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    xp_reward   INTEGER NOT NULL DEFAULT 0 CHECK (xp_reward >= 0),
    is_daily    BOOLEAN NOT NULL DEFAULT FALSE,
    tier_id     INTEGER REFERENCES tiers (id) ON DELETE SET NULL
);

-- user mission completions
CREATE TABLE IF NOT EXISTS user_missions (
    user_uid      UUID NOT NULL REFERENCES users (uid) ON DELETE CASCADE,
    mission_id    INTEGER NOT NULL REFERENCES missions (id) ON DELETE CASCADE,
    completed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_uid, mission_id)
);

-- user analytics logs
CREATE TABLE IF NOT EXISTS user_analytics_logs (
    id          SERIAL PRIMARY KEY,
    user_uid    UUID NOT NULL REFERENCES users (uid) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories (id) ON DELETE SET NULL,
    post_id     INTEGER REFERENCES posts (id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- activity audit trail
CREATE TABLE IF NOT EXISTS activity_logs (
    id                 SERIAL PRIMARY KEY,
    user_uid           UUID NOT NULL REFERENCES users (uid) ON DELETE CASCADE,
    action_description TEXT NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS eco_wrapped (
    id              SERIAL PRIMARY KEY,         				                        -- auto-incrementing unique snapshot id
    user_uid        UUID NOT NULL REFERENCES users (uid) ON DELETE CASCADE,             -- fk to the user this snapshot belongs to
    year            INTEGER NOT NULL CHECK (year >= 2026),                              -- the year this wrapped covers, 2026 is the earliest valid year
    ranking         NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (ranking BETWEEN 0 AND 100),  -- percentile rank 0-100, based on total xp accumulated
    -- post_count      INTEGER NOT NULL DEFAULT 0 CHECK (post_count >= 0),              -- total posts shared by the user that year, does not have a table yet
    tree_count      INTEGER NOT NULL DEFAULT 0 CHECK (tree_count >= 0),                 -- total trees planted by the user that year
    tier_name       VARCHAR(100) NOT NULL DEFAULT 'seed',                               -- tier name reached at year-end, copied from tiers to preserve history
    total_xp        INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),                   -- total xp at year-end, copied from users to preserve history
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),                                 -- timestamp of when this snapshot was generated
    UNIQUE (user_uid, year)                                                             -- one snapshot per user per year, prevents duplicates
);


-- fk indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_current_tier_id ON users (current_tier_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_uid ON posts (user_uid);
CREATE INDEX IF NOT EXISTS idx_user_missions_mission_id ON user_missions (mission_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_uid ON activity_logs (user_uid);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs (created_at);
CREATE INDEX IF NOT EXISTS idx_eco_wrapped_user_uid ON eco_wrapped (user_uid);            
CREATE INDEX IF NOT EXISTS idx_eco_wrapped_year ON eco_wrapped (year);  