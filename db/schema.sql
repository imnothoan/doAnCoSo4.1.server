-- ============================================================================
-- ConnectSphere Database Schema for Supabase
-- UniVini-like App Backend
-- ============================================================================

-- ============================================================================
-- USERS TABLE (Enhanced)
-- ============================================================================
-- Extended user profile to support all app features
ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Chilling' CHECK (status IN ('Traveling', 'Learning', 'Chilling', 'Open to Chat'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS country TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS flag TEXT; -- country flag emoji or code
ALTER TABLE users ADD COLUMN IF NOT EXISTS interests TEXT[]; -- array of interests
ALTER TABLE users ADD COLUMN IF NOT EXISTS specialties JSONB DEFAULT '{}'; -- { "From": "Vietnam", "Interests": ["Language exchange"], ... }
ALTER TABLE users ADD COLUMN IF NOT EXISTS about_me TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE users ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_completion_percentage INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_confirmed BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS max_friends INTEGER DEFAULT 16; -- normal limit, unlimited for premium
ALTER TABLE users ADD COLUMN IF NOT EXISTS background_image TEXT; -- URL for background image in Tinder-like hangout feature
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT; -- Bcrypt hashed password for authentication

-- Index for background images
CREATE INDEX IF NOT EXISTS idx_users_background_image ON users(background_image) WHERE background_image IS NOT NULL;

-- Index for email lookups during login
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ============================================================================
-- USER LANGUAGES
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_languages (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  language TEXT NOT NULL, -- e.g., 'English', 'Vietnamese', 'Chinese'
  proficiency TEXT DEFAULT 'Intermediate' CHECK (proficiency IN ('Native', 'Fluent', 'Intermediate', 'Beginner', 'Learning')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(username, language)
);

CREATE INDEX IF NOT EXISTS idx_user_languages_username ON user_languages(username);
CREATE INDEX IF NOT EXISTS idx_user_languages_language ON user_languages(language);

-- ============================================================================
-- USER COUNTRIES (Lived/Visited)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_countries (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  country TEXT NOT NULL,
  country_type TEXT NOT NULL CHECK (country_type IN ('lived', 'visited')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(username, country, country_type)
);

CREATE INDEX IF NOT EXISTS idx_user_countries_username ON user_countries(username);

-- ============================================================================
-- EVENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  details TEXT, -- long-form description
  image_url TEXT,
  hosted_by TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  date_start TIMESTAMP WITH TIME ZONE NOT NULL,
  date_end TIMESTAMP WITH TIME ZONE NOT NULL,
  schedule TEXT, -- e.g., "weekly 07:30 PM - 11:30 PM"
  is_recurring BOOLEAN DEFAULT false,
  recurrence_pattern TEXT, -- e.g., "weekly", "monthly"
  entrance_fee TEXT DEFAULT 'Free',
  has_pricing_menu BOOLEAN DEFAULT false,
  max_participants INTEGER,
  status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_hosted_by ON events(hosted_by);
CREATE INDEX IF NOT EXISTS idx_events_date_start ON events(date_start);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_location ON events USING gist(point(longitude, latitude));

-- ============================================================================
-- EVENT PARTICIPANTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS event_participants (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  status TEXT DEFAULT 'interested' CHECK (status IN ('interested', 'going', 'not_going', 'maybe')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(event_id, username)
);

CREATE INDEX IF NOT EXISTS idx_event_participants_event ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_username ON event_participants(username);
CREATE INDEX IF NOT EXISTS idx_event_participants_status ON event_participants(status);

-- ============================================================================
-- EVENT INVITATIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS event_invitations (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  inviter_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  invitee_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  responded_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(event_id, invitee_username)
);

CREATE INDEX IF NOT EXISTS idx_event_invitations_event ON event_invitations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_invitations_invitee ON event_invitations(invitee_username);

-- ============================================================================
-- EVENT COMMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS event_comments (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  author_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT, -- optional image attachment
  parent_id BIGINT REFERENCES event_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_event_comments_event ON event_comments(event_id);
CREATE INDEX IF NOT EXISTS idx_event_comments_author ON event_comments(author_username);
CREATE INDEX IF NOT EXISTS idx_event_comments_parent ON event_comments(parent_id);

-- ============================================================================
-- HANGOUTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS hangouts (
  id BIGSERIAL PRIMARY KEY,
  creator_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  title TEXT,
  description TEXT,
  activities TEXT[], -- array of activities: ['drink tea or coffee', 'grab beers', etc.]
  languages TEXT[], -- preferred languages for the hangout
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  location_name TEXT,
  max_distance_km INTEGER DEFAULT 10, -- maximum distance filter
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'active', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hangouts_creator ON hangouts(creator_username);
CREATE INDEX IF NOT EXISTS idx_hangouts_status ON hangouts(status);
CREATE INDEX IF NOT EXISTS idx_hangouts_location ON hangouts USING gist(point(longitude, latitude));

-- ============================================================================
-- HANGOUT PARTICIPANTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS hangout_participants (
  id BIGSERIAL PRIMARY KEY,
  hangout_id BIGINT NOT NULL REFERENCES hangouts(id) ON DELETE CASCADE,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  status TEXT DEFAULT 'interested' CHECK (status IN ('interested', 'joined', 'left')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(hangout_id, username)
);

CREATE INDEX IF NOT EXISTS idx_hangout_participants_hangout ON hangout_participants(hangout_id);
CREATE INDEX IF NOT EXISTS idx_hangout_participants_username ON hangout_participants(username);

-- ============================================================================
-- HANGOUT CONNECTIONS (History)
-- ============================================================================
CREATE TABLE IF NOT EXISTS hangout_connections (
  id BIGSERIAL PRIMARY KEY,
  user1_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  user2_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  hangout_id BIGINT REFERENCES hangouts(id) ON DELETE SET NULL,
  connection_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  location1_lat DOUBLE PRECISION,
  location1_lng DOUBLE PRECISION,
  location2_lat DOUBLE PRECISION,
  location2_lng DOUBLE PRECISION,
  CHECK (user1_username < user2_username) -- ensure unique pair ordering
);

CREATE INDEX IF NOT EXISTS idx_hangout_connections_user1 ON hangout_connections(user1_username);
CREATE INDEX IF NOT EXISTS idx_hangout_connections_user2 ON hangout_connections(user2_username);
CREATE INDEX IF NOT EXISTS idx_hangout_connections_date ON hangout_connections(connection_date);

-- ============================================================================
-- USER HANGOUT STATUS
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_hangout_status (
  username TEXT PRIMARY KEY REFERENCES users(username) ON DELETE CASCADE,
  is_available BOOLEAN DEFAULT false,
  current_activity TEXT, -- what they're currently doing
  activities TEXT[], -- selected activities they're open to
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- COMMUNITIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS communities (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  image_url TEXT,
  created_by TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  member_count INTEGER DEFAULT 0,
  post_count INTEGER DEFAULT 0,
  is_private BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_communities_name ON communities(name);
CREATE INDEX IF NOT EXISTS idx_communities_created_by ON communities(created_by);

-- ============================================================================
-- COMMUNITY MEMBERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS community_members (
  id BIGSERIAL PRIMARY KEY,
  community_id BIGINT NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(community_id, username)
);

CREATE INDEX IF NOT EXISTS idx_community_members_community ON community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_username ON community_members(username);

-- ============================================================================
-- COMMUNITY POSTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS community_posts (
  id BIGSERIAL PRIMARY KEY,
  community_id BIGINT NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  author_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_posts_community ON community_posts(community_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_author ON community_posts(author_username);
CREATE INDEX IF NOT EXISTS idx_community_posts_created ON community_posts(created_at);

-- ============================================================================
-- COMMUNITY POST LIKES
-- ============================================================================
CREATE TABLE IF NOT EXISTS community_post_likes (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, username)
);

CREATE INDEX IF NOT EXISTS idx_community_post_likes_post ON community_post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_community_post_likes_username ON community_post_likes(username);

-- ============================================================================
-- COMMUNITY POST COMMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS community_post_comments (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  author_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  content TEXT NOT NULL,
  parent_id BIGINT REFERENCES community_post_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_post_comments_post ON community_post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_community_post_comments_author ON community_post_comments(author_username);
CREATE INDEX IF NOT EXISTS idx_community_post_comments_parent ON community_post_comments(parent_id);

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id BIGSERIAL PRIMARY KEY,
  recipient_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  sender_username TEXT REFERENCES users(username) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'follow', 'like_post', 'comment_post', 'mention', 
    'event_invitation', 'event_update', 'event_comment',
    'hangout_request', 'hangout_match',
    'message', 'community_post', 'system'
  )),
  title TEXT,
  content TEXT NOT NULL,
  data JSONB DEFAULT '{}', -- additional data like event_id, post_id, etc.
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_username);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

-- ============================================================================
-- QUICK MESSAGES
-- ============================================================================
CREATE TABLE IF NOT EXISTS quick_messages (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  shortcut TEXT NOT NULL, -- e.g., "/x"
  message TEXT NOT NULL, -- e.g., "Xin chào"
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(username, shortcut)
);

CREATE INDEX IF NOT EXISTS idx_quick_messages_username ON quick_messages(username);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View for calculating user distance (requires PostGIS or custom function)
-- This is a placeholder - actual implementation depends on Supabase setup

-- View for event summaries with participant count
CREATE OR REPLACE VIEW v_event_summary AS
SELECT 
  e.*,
  COUNT(DISTINCT ep.username) FILTER (WHERE ep.status IN ('interested', 'going')) as participant_count,
  COUNT(DISTINCT ec.id) as comment_count
FROM events e
LEFT JOIN event_participants ep ON e.id = ep.event_id
LEFT JOIN event_comments ec ON e.id = ec.event_id
GROUP BY e.id;

-- View for community summaries
CREATE OR REPLACE VIEW v_community_summary AS
SELECT 
  c.*,
  COUNT(DISTINCT cm.username) as actual_member_count,
  COUNT(DISTINCT cp.id) as actual_post_count
FROM communities c
LEFT JOIN community_members cm ON c.id = cm.community_id
LEFT JOIN community_posts cp ON c.id = cp.community_id
GROUP BY c.id;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to calculate profile completion percentage
CREATE OR REPLACE FUNCTION calculate_profile_completion(user_username TEXT)
RETURNS INTEGER AS $$
DECLARE
  completion INTEGER := 0;
  user_rec RECORD;
BEGIN
  SELECT * INTO user_rec FROM users WHERE username = user_username;
  
  IF user_rec.name IS NOT NULL AND user_rec.name != '' THEN completion := completion + 10; END IF;
  IF user_rec.bio IS NOT NULL AND user_rec.bio != '' THEN completion := completion + 10; END IF;
  IF user_rec.about_me IS NOT NULL AND user_rec.about_me != '' THEN completion := completion + 10; END IF;
  IF user_rec.avatar IS NOT NULL AND user_rec.avatar != '' THEN completion := completion + 15; END IF;
  IF user_rec.email_confirmed THEN completion := completion + 15; END IF;
  IF user_rec.country IS NOT NULL THEN completion := completion + 5; END IF;
  IF user_rec.city IS NOT NULL THEN completion := completion + 5; END IF;
  
  -- Check for languages
  IF EXISTS (SELECT 1 FROM user_languages WHERE username = user_username) THEN
    completion := completion + 10;
  END IF;
  
  -- Check for interests
  IF user_rec.interests IS NOT NULL AND array_length(user_rec.interests, 1) > 0 THEN
    completion := completion + 10;
  END IF;
  
  -- Check for countries
  IF EXISTS (SELECT 1 FROM user_countries WHERE username = user_username) THEN
    completion := completion + 10;
  END IF;
  
  RETURN LEAST(completion, 100);
END;
$$ LANGUAGE plpgsql;

-- Function to update event participant count
CREATE OR REPLACE FUNCTION update_event_participant_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Update is handled by the view, but we could cache it in the events table if needed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to increment community member count
CREATE OR REPLACE FUNCTION increment_community_members(community_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE communities 
  SET member_count = member_count + 1 
  WHERE id = community_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement community member count
CREATE OR REPLACE FUNCTION decrement_community_members(community_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE communities 
  SET member_count = GREATEST(member_count - 1, 0)
  WHERE id = community_id;
END;
$$ LANGUAGE plpgsql;

-- Function to increment community post count
CREATE OR REPLACE FUNCTION increment_community_posts(community_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE communities 
  SET post_count = post_count + 1 
  WHERE id = community_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement community post count
CREATE OR REPLACE FUNCTION decrement_community_posts(community_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE communities 
  SET post_count = GREATEST(post_count - 1, 0)
  WHERE id = community_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- CONVERSATION OVERVIEW VIEW (for unread counts and last message)
-- ============================================================================
-- Note: This view can be used for optimized queries, but the code also has
-- a fallback implementation that calculates unread counts directly
CREATE OR REPLACE VIEW v_conversation_overview AS
SELECT 
  cm.conversation_id,
  cm.username,
  MAX(m.created_at) as last_message_at,
  COUNT(m.id) FILTER (
    WHERE m.sender_username != cm.username
    AND NOT EXISTS (
      SELECT 1 FROM message_reads mr 
      WHERE mr.message_id = m.id 
      AND mr.username = cm.username
    )
  ) as unread_count
FROM conversation_members cm
LEFT JOIN messages m ON m.conversation_id = cm.conversation_id
GROUP BY cm.conversation_id, cm.username;

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update_updated_at trigger to relevant tables
DROP TRIGGER IF EXISTS update_events_updated_at ON events;
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_hangouts_updated_at ON hangouts;
CREATE TRIGGER update_hangouts_updated_at BEFORE UPDATE ON hangouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_communities_updated_at ON communities;
CREATE TRIGGER update_communities_updated_at BEFORE UPDATE ON communities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_community_posts_updated_at ON community_posts;
CREATE TRIGGER update_community_posts_updated_at BEFORE UPDATE ON community_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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

-- ============================================================================
-- USER THEME PREFERENCES
-- ============================================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS theme_preference TEXT DEFAULT 'blue' CHECK (theme_preference IN ('blue', 'yellow'));

-- ============================================================================
-- USER SUBSCRIPTIONS (Premium Features)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('free', 'pro')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE, -- NULL for free plan, set for pro plan
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(username)
);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_username ON user_subscriptions(username);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);

DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON user_subscriptions;
CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PAYMENT TRANSACTIONS (Test Payment History)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payment_transactions (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'VND',
  plan_type TEXT NOT NULL CHECK (plan_type IN ('pro')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT DEFAULT 'test', -- test payment
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_username ON payment_transactions(username);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Optional, configure based on needs
-- ============================================================================
-- Enable RLS on sensitive tables
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE events ENABLE ROW LEVEL SECURITY;
-- etc.

-- Apply update_updated_at trigger to community_events
DROP TRIGGER IF EXISTS update_community_events_updated_at ON community_events;
CREATE TRIGGER update_community_events_updated_at BEFORE UPDATE ON community_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SEED DATA (Optional)
-- ============================================================================
-- You can add seed data here for testing
