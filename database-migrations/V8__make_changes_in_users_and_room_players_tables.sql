-- Remove the NOT NULL constraint from the email column
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- Remove redundant guest columns
ALTER TABLE room_players DROP COLUMN IF EXISTS guest_session_id;
ALTER TABLE room_players DROP COLUMN IF EXISTS guest_display_name;


