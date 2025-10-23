ALTER TABLE room_players DROP CONSTRAINT IF EXISTS room_players_room_id_fkey;
ALTER TABLE game_state DROP CONSTRAINT IF EXISTS game_state_room_id_fkey;
ALTER TABLE game_state DROP CONSTRAINT IF EXISTS game_state_turn_player_id_fkey;

ALTER TABLE room_players
    ADD CONSTRAINT room_players_room_id_fkey
        FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE;

ALTER TABLE game_state
    ADD CONSTRAINT game_state_room_id_fkey
        FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE;

ALTER TABLE game_state
    ADD CONSTRAINT game_state_turn_player_id_fkey
        FOREIGN KEY (turn_player_id) REFERENCES room_players(id) ON DELETE CASCADE;