CREATE TABLE characters (
   id UUID PRIMARY KEY,
   name TEXT NOT NULL,
   image_url TEXT NOT NULL
);

CREATE TABLE character_sets (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    created_by TEXT NOT NULL,
    is_public BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE character_set_characters (
    character_set_id UUID NOT NULL,
    character_id UUID NOT NULL,
    PRIMARY KEY (character_set_id, character_id),
    CONSTRAINT fk_character_set
      FOREIGN KEY (character_set_id) REFERENCES character_sets(id)
          ON DELETE CASCADE,
    CONSTRAINT fk_character
      FOREIGN KEY (character_id) REFERENCES characters(id)
          ON DELETE CASCADE
);

INSERT INTO characters (id, name, image_url)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'Alice', 'https://example.com/images/alice.png'),
    ('00000000-0000-0000-0000-000000000002', 'Bob', 'https://example.com/images/bob.png'),
    ('00000000-0000-0000-0000-000000000003', 'Charlie', 'https://example.com/images/charlie.png'),
    ('00000000-0000-0000-0000-000000000004', 'Diana', 'https://example.com/images/diana.png');

INSERT INTO character_sets (id, name, created_by, is_public, created_at)
VALUES (
   '00000000-0000-0000-0000-000000000001',
   'Default Set',
   'system',
   TRUE,
   NOW()
);

INSERT INTO character_set_characters (character_set_id, character_id)
VALUES
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002'),
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003'),
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004');

ALTER TABLE rooms
    ADD COLUMN character_set_id UUID;

UPDATE rooms
SET character_set_id = '00000000-0000-0000-0000-000000000001'
WHERE character_set_id IS NULL;

ALTER TABLE rooms
    ALTER COLUMN character_set_id SET NOT NULL;

ALTER TABLE rooms
    ADD CONSTRAINT fk_character_set
        FOREIGN KEY (character_set_id)
            REFERENCES character_sets(id)
            ON DELETE RESTRICT;

ALTER TABLE room_players
    ADD COLUMN character_to_guess_id UUID;

ALTER TABLE room_players
    ADD CONSTRAINT fk_character
        FOREIGN KEY (character_to_guess_id)
            REFERENCES characters(id)
            ON DELETE RESTRICT;