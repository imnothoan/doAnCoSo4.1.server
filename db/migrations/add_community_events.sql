-- ============================================================================
-- COMMUNITY EVENTS TABLE
-- For Facebook-style events within communities
-- ============================================================================

CREATE TABLE IF NOT EXISTS community_events (
  id BIGSERIAL PRIMARY KEY,
  community_id BIGINT NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  created_by TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  location TEXT,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_events_community ON community_events(community_id);
CREATE INDEX IF NOT EXISTS idx_community_events_created_by ON community_events(created_by);
CREATE INDEX IF NOT EXISTS idx_community_events_start_time ON community_events(start_time);

-- ============================================================================
-- COMMUNITY EVENT PARTICIPANTS
-- Track going/interested status for community events
-- ============================================================================

CREATE TABLE IF NOT EXISTS community_event_participants (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES community_events(id) ON DELETE CASCADE,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('going', 'interested')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(event_id, username)
);

CREATE INDEX IF NOT EXISTS idx_community_event_participants_event ON community_event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_community_event_participants_username ON community_event_participants(username);
CREATE INDEX IF NOT EXISTS idx_community_event_participants_status ON community_event_participants(status);

-- Apply update_updated_at trigger to community_events
DROP TRIGGER IF EXISTS update_community_events_updated_at ON community_events;
CREATE TRIGGER update_community_events_updated_at BEFORE UPDATE ON community_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
