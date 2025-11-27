-- Dropping the old host_id column if it exists
ALTER TABLE rooms DROP COLUMN IF EXISTS host_id;

-- First, add the column as nullable
ALTER TABLE rooms ADD COLUMN host_id UUID;

-- Handle existing rows - choose one of these options:
DELETE FROM rooms WHERE host_id IS NULL;

-- Add the new host_id column as a foreign key to users table
ALTER TABLE rooms ALTER COLUMN host_id SET NOT NULL;

-- Add foreign key constraint
ALTER TABLE rooms 
ADD CONSTRAINT fk_rooms_host 
FOREIGN KEY (host_id) REFERENCES users(id) 
ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX idx_rooms_host_id ON rooms(host_id);
