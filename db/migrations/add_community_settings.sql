-- Add settings columns to communities table
ALTER TABLE communities ADD COLUMN IF NOT EXISTS requires_post_approval BOOLEAN DEFAULT false;
ALTER TABLE communities ADD COLUMN IF NOT EXISTS requires_member_approval BOOLEAN DEFAULT false;

-- Add status column to community_members for join requests
ALTER TABLE community_members ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'approved' CHECK (status IN ('approved', 'pending', 'rejected', 'banned'));

-- Add status column to community_posts for post approval (if not exists)
-- It seems posts table already has status, but let's check community_posts
-- Wait, the schema has 'community_posts' table but the routes use 'posts' table with community_id?
-- Let's check community.routes.js again. It uses 'posts' table.
-- Schema says 'community_posts' table exists.
-- Route says: supabase.from("posts").insert(...)
-- This implies the schema I saw might be outdated or unused, OR the code is using a different table.
-- Let's check 'posts' table in schema.
-- I don't see 'posts' table in the schema I viewed! I saw 'community_posts'.
-- Wait, let me check schema.sql again.
-- Line 69: events
-- Line 151: hangouts
-- Line 220: communities
-- Line 254: community_posts
-- But the code uses 'posts'.
-- Maybe 'posts' is a general table?
-- I need to verify which table is actually used.
-- The code in community.routes.js uses 'posts'.
-- The schema.sql might be a proposed schema or an old one.
-- Let's check if there is a 'posts' table in the codebase or if I missed it.
-- I'll search for 'create table posts' in the codebase.
