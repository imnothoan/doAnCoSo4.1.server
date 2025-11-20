# Deployment Checklist - Community Features Update

## ✅ Pre-Deployment Verification

### Code Changes Summary
- ✅ **Video/Voice Calling Removed**: All WebRTC-related WebSocket events removed
- ✅ **Community Chat Added**: Full WebSocket-based real-time chat for communities
- ✅ **PRO User Restriction**: Only PRO users can create communities
- ✅ **Admin Features**: Role management, member kick, avatar/cover uploads
- ✅ **Join Request System**: Private communities with approval workflow
- ✅ **Image Upload Fixed**: Changed bucket from 'messages' to 'chat-image'
- ✅ **Security**: Multer upgraded to 2.0.2, CodeQL clean (0 alerts)

## 📋 Deployment Steps

### 1. Database Migration

#### Step 1.1: Run Migration SQL
Execute the migration script on your Supabase database:

```sql
-- File: db/migrations/add_community_features.sql

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
```

**Verification:**
```sql
-- Verify columns exist
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'conversations' AND column_name = 'community_id';

SELECT column_name FROM information_schema.columns 
WHERE table_name = 'communities' AND column_name = 'cover_image';

-- Verify table exists
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'community_join_requests';
```

#### Step 1.2: Verify Existing Data
```sql
-- Check if any communities already exist
SELECT id, name, created_by, is_private FROM communities LIMIT 5;

-- Check if users table has is_premium column
SELECT username, is_premium FROM users LIMIT 5;
```

### 2. Supabase Storage Setup

#### Step 2.1: Create Storage Buckets

In Supabase Dashboard → Storage → Create New Bucket:

**Bucket 1: chat-image**
- Name: `chat-image`
- Public: ✅ Yes
- File size limit: 10 MB (10485760 bytes)
- Allowed MIME types: `image/jpeg`, `image/png`, `image/jpg`

**Bucket 2: community**
- Name: `community`
- Public: ✅ Yes
- File size limit: 10 MB (10485760 bytes)
- Allowed MIME types: `image/jpeg`, `image/png`, `image/jpg`

#### Step 2.2: Set Bucket Policies

For both buckets, add these policies:

**Policy: Public Read Access**
```sql
-- Policy name: Public read access
-- Allowed operations: SELECT
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat-image');

CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'community');
```

**Policy: Authenticated Upload**
```sql
-- Policy name: Authenticated users can upload
-- Allowed operations: INSERT
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'chat-image' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'community' AND auth.role() = 'authenticated');
```

### 3. Environment Configuration

#### Step 3.1: Update .env File

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key

# CORS Origins (comma-separated)
CORS_ORIGIN=http://localhost:3000,http://localhost:19006,http://localhost:8081,https://your-production-domain.com

# Storage Buckets (UPDATED)
POSTS_BUCKET=posts
AVATARS_BUCKET=avatars
MESSAGES_BUCKET=chat-image
COMMUNITY_BUCKET=community

# Server Port
PORT=3000

# Node Environment
NODE_ENV=production

# Stripe Payment Configuration
STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key_here
```

#### Step 3.2: Verify Environment Variables

```bash
# Test environment loading
node -e "require('dotenv').config(); console.log('SUPABASE_URL:', process.env.SUPABASE_URL); console.log('MESSAGES_BUCKET:', process.env.MESSAGES_BUCKET);"
```

### 4. Server Deployment

#### Step 4.1: Install Dependencies

```bash
npm install
```

Expected output: All packages installed, 0 vulnerabilities

#### Step 4.2: Test Server Locally (Optional)

```bash
# Start server in development mode
npm run dev
```

Verify:
- ✅ Server starts without errors
- ✅ WebSocket server initialized
- ✅ All routes loaded
- ✅ Health check endpoint responds: `GET http://localhost:3000/health`

#### Step 4.3: Deploy to Production

Deploy using your preferred method:
- Railway: `railway up`
- Render: Push to connected Git repo
- Heroku: `git push heroku main`
- PM2: `pm2 start index.js --name connectsphere-server`

### 5. Post-Deployment Testing

#### Test 1: Health Check
```bash
curl https://your-domain.com/health
# Expected: {"ok":true,"environment":"production"}
```

#### Test 2: PRO User Restriction
```bash
# Non-PRO user tries to create community
curl -X POST https://your-domain.com/communities \
  -H "Content-Type: application/json" \
  -d '{"created_by":"regular_user","name":"Test Community"}'

# Expected: {"message":"Only PRO users can create communities.","requiresPro":true}
```

#### Test 3: Private Community Join
```bash
# Try to join private community
curl -X POST https://your-domain.com/communities/1/join \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user"}'

# Expected (if private): {"message":"Cannot join private community directly...","requiresRequest":true}
```

#### Test 4: Community Chat WebSocket
```javascript
// Test WebSocket connection
const socket = io('https://your-domain.com', {
  auth: { token: 'your-base64-encoded-token' }
});

socket.on('connect', () => {
  console.log('Connected!');
  
  // Join community chat
  socket.emit('join_community_chat', { communityId: 1 });
  
  // Send test message
  socket.emit('send_community_message', {
    communityId: 1,
    senderUsername: 'test_user',
    content: 'Hello community!'
  });
});

socket.on('new_community_message', (message) => {
  console.log('New message:', message);
});
```

#### Test 5: Image Upload
```bash
# Test image upload in message
curl -X POST https://your-domain.com/messages/conversations/1/messages \
  -H "Content-Type: multipart/form-data" \
  -F "sender_username=test_user" \
  -F "content=Check this image!" \
  -F "image=@/path/to/test-image.jpg"

# Verify image URL in response uses 'chat-image' bucket
```

#### Test 6: Community Avatar/Cover Upload
```bash
# Upload community avatar (as admin)
curl -X POST https://your-domain.com/communities/1/avatar \
  -H "Content-Type: multipart/form-data" \
  -F "actor=admin_user" \
  -F "avatar=@/path/to/avatar.jpg"

# Verify image URL uses 'community' bucket
```

### 6. Client Configuration Update

Update client's API URL to point to production server:

```javascript
// In client .env or config
EXPO_PUBLIC_API_URL=https://your-domain.com
```

### 7. Monitor and Verify

#### Check Server Logs
```bash
# If using PM2
pm2 logs connectsphere-server

# If using Railway/Render
# Check logs in dashboard
```

Look for:
- ✅ "Server listening on port X"
- ✅ "WebSocket server initialized"
- ✅ "WebSocket client connected" when users connect
- ✅ No error messages

#### Monitor Database
```sql
-- Check if conversations are being created for communities
SELECT id, type, community_id, created_by 
FROM conversations 
WHERE community_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- Check join requests
SELECT jr.id, jr.username, jr.status, c.name as community_name
FROM community_join_requests jr
JOIN communities c ON jr.community_id = c.id
ORDER BY jr.created_at DESC
LIMIT 10;

-- Check community messages
SELECT m.id, m.sender_username, m.content, c.name as community_name
FROM messages m
JOIN conversations conv ON m.conversation_id = conv.id
JOIN communities c ON conv.community_id = c.id
ORDER BY m.created_at DESC
LIMIT 10;
```

## 🚨 Troubleshooting

### Issue: "Cannot join community chat"
**Solution:**
1. Verify user is a member of the community
2. Check if conversation exists for the community
3. Verify WebSocket connection is established

### Issue: "Image upload fails"
**Solution:**
1. Verify storage buckets exist: `chat-image` and `community`
2. Check bucket permissions (public read, authenticated write)
3. Verify file size is under 10MB
4. Check CORS settings in Supabase

### Issue: "Join request not working"
**Solution:**
1. Verify `community_join_requests` table exists
2. Check community `is_private` field is true
3. Ensure admin has proper permissions

### Issue: "Non-PRO user can create community"
**Solution:**
1. Verify user's `is_premium` field in database
2. Check if PRO check logic is in place in community routes
3. Verify JWT token is correctly decoded

## 📊 Success Metrics

After deployment, verify these metrics:

- ✅ Server uptime: 99%+
- ✅ WebSocket connections: Stable
- ✅ Community creations: Only from PRO users
- ✅ Join requests: Working for private communities
- ✅ Image uploads: Successful to correct buckets
- ✅ Community chat: Real-time message delivery
- ✅ No security vulnerabilities: CodeQL clean
- ✅ No 5xx errors in logs

## 🎯 Rollback Plan

If issues arise, rollback steps:

1. **Revert server deployment** to previous version
2. **Keep database changes** - they are backward compatible
3. **Storage buckets** - can remain, won't cause issues
4. **Client** - revert client if it depends on new features

## 📞 Support

For issues or questions:
1. Check server logs first
2. Review this checklist
3. Consult `COMMUNITY_UPDATE_GUIDE.md`
4. Check client repository for matching implementation

---

**Deployment Completed By:** _______________  
**Date:** _______________  
**Server Version:** 1.1.0 (Community Features)  
**Status:** ☐ Success ☐ Failed ☐ Rolled Back
