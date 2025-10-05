CREATE TABLE rooms (
    id UUID PRIMARY KEY,
    host_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL,
    max_players INT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    started_at TIMESTAMP,
    finished_at TIMESTAMP
);

CREATE TABLE room_players (
    id UUID PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES rooms(id),
    user_id UUID,
    is_host BOOLEAN NOT NULL,
    is_ready BOOLEAN NOT NULL,
    joined_at TIMESTAMP NOT NULL
);

CREATE TABLE game_state (
    id UUID PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES rooms(id),
    turn_player_id UUID REFERENCES room_players(id),
    round_number INT,
    current_question TEXT,
    last_answer TEXT,
    winner_id UUID
);
