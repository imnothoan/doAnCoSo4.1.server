-- ============================================================================
-- Add password_hash column to users table for secure authentication
-- Migration: add_password_hash
-- ============================================================================

-- Add password_hash column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Create index for faster email lookups during login
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Add comment
COMMENT ON COLUMN users.password_hash IS 'Bcrypt hashed password for authentication';
