-- V1__create_user_table.sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_username ON users(username);

CREATE INDEX idx_users_created_at ON users(created_at);

-- Remove old column user_id column
ALTER TABLE room_players 
    DROP COLUMN IF EXISTS user_id;

-- Add correct user reference (another user_id column)
ALTER TABLE room_players
    ADD COLUMN user_id UUID NOT NULL;

-- If there are existing rows
ALTER TABLE room_players ALTER COLUMN user_id SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE room_players
    ADD CONSTRAINT fk_room_players_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE;

-- Index for faster lookup
CREATE INDEX idx_room_players_user_id
    ON room_players(user_id);
