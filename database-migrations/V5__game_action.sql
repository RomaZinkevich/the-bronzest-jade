ALTER TABLE game_state
DROP COLUMN IF EXISTS current_question,
DROP COLUMN IF EXISTS last_answer,
ADD COLUMN turn_phase VARCHAR(20) NOT NULL DEFAULT 'ASKING';


CREATE TABLE game_action (
     id UUID PRIMARY KEY,

     game_state_id UUID NOT NULL,
     asking_player_id UUID NOT NULL,
     answering_player_id UUID,

     question TEXT NOT NULL,
     answer TEXT,
     round_number INTEGER NOT NULL,

     CONSTRAINT fk_game_action_game_state
         FOREIGN KEY (game_state_id)
             REFERENCES game_state (id)
             ON DELETE CASCADE,

     CONSTRAINT fk_game_action_asking_player
         FOREIGN KEY (asking_player_id)
             REFERENCES room_players (id)
             ON DELETE CASCADE,

     CONSTRAINT fk_game_action_answering_player
         FOREIGN KEY (answering_player_id)
             REFERENCES room_players (id)
             ON DELETE CASCADE
);
