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

-- Make user_id nullable to support guest users
ALTER TABLE room_players 
    ADD COLUMN user_id UUID;

-- Add guest columns
ALTER TABLE room_players
    ADD COLUMN guest_display_name VARCHAR(255),
    ADD COLUMN guest_session_id UUID;

-- Add foreign key constraint for authenticated users
ALTER TABLE room_players
    ADD CONSTRAINT fk_room_players_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE;

-- Add constraint to ensure at least one user type is present
ALTER TABLE room_players 
    ADD CONSTRAINT chk_user_or_guest 
    CHECK (
        (user_id IS NOT NULL) OR (guest_session_id IS NOT NULL)
    );

-- Index for faster lookups
CREATE INDEX idx_room_players_user_id ON room_players(user_id);
CREATE INDEX idx_room_players_guest_session ON room_players(guest_session_id);
