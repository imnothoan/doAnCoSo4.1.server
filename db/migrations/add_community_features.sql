-- ============================================================================
-- Community Features Migration
-- Adds support for community chat, join requests, and cover images
-- ============================================================================

-- Add community_id to conversations table for community chats
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS community_id BIGINT REFERENCES communities(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_conversations_community ON conversations(community_id) WHERE community_id IS NOT NULL;

-- Add cover_image to communities table
ALTER TABLE communities ADD COLUMN IF NOT EXISTS cover_image TEXT;
CREATE INDEX IF NOT EXISTS idx_communities_cover_image ON communities(cover_image) WHERE cover_image IS NOT NULL;

-- Create community_join_requests table for private community approval
CREATE TABLE IF NOT EXISTS community_join_requests (
  id BIGSERIAL PRIMARY KEY,
  community_id BIGINT NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by TEXT REFERENCES users(username) ON DELETE SET NULL,
  UNIQUE(community_id, username)
);

CREATE INDEX IF NOT EXISTS idx_community_join_requests_community ON community_join_requests(community_id);
CREATE INDEX IF NOT EXISTS idx_community_join_requests_username ON community_join_requests(username);
CREATE INDEX IF NOT EXISTS idx_community_join_requests_status ON community_join_requests(status);
