-- ============================================================================
-- Migration: Add background_image column to users table
-- Date: 2025-11-12
-- Description: Add support for background images in user profiles for 
--              Tinder-like hangout feature
-- ============================================================================

-- Add background_image column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS background_image TEXT;

-- Create index to improve query performance when filtering users with background images
CREATE INDEX IF NOT EXISTS idx_users_background_image ON users(background_image) WHERE background_image IS NOT NULL;

-- Add comment to document the column
COMMENT ON COLUMN users.background_image IS 'Public URL of user background image stored in Supabase Storage (background-images bucket)';
