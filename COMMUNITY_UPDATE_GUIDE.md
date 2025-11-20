# Community Features Update Guide

This guide explains the latest update to the server that adds comprehensive community features and removes video/voice calling functionality.

## 🎉 What's New

### ❌ Removed Features
- **Video/Voice Calling**: All WebRTC-based calling features have been removed as they are not compatible with Expo Go

### ✨ Added Features

#### 1. PRO User Community Creation
- Only users with `is_premium = true` can create new communities
- Non-PRO users will receive an error with `requiresPro: true` flag

#### 2. Community Admin Features
- **Role Management**: Admins can promote/demote members to admin, moderator, or member roles
- **Member Moderation**: Admins can kick members from the community
- **Avatar Upload**: Upload community avatar image (`/communities/:id/avatar`)
- **Cover Upload**: Upload community cover image (`/communities/:id/cover`)

#### 3. Private Communities with Join Requests
- Communities can be marked as `is_private: true`
- Users must send join requests to join private communities
- Admins can approve or reject join requests
- Automatic member addition upon approval

#### 4. Real-Time Community Chat
- Each community has its own WebSocket-based chat room
- WebSocket events:
  - `join_community_chat` - Join a community chat room
  - `leave_community_chat` - Leave a community chat room
  - `send_community_message` - Send a message to the community
  - `new_community_message` - Receive new messages
  - `community_typing` - Typing indicators
- REST endpoint: `GET /communities/:id/chat/messages` - Get chat history

#### 5. Image Sending in Messages
- Fixed image upload bucket name from `messages` to `chat-image`
- Images now properly upload and display in conversations

## 🗄️ Database Migration

### Required Steps

1. **Run the Migration Script**
   
   Execute the SQL migration on your Supabase database:
   ```bash
   # Location: db/migrations/add_community_features.sql
   ```

   This migration adds:
   - `community_id` column to `conversations` table
   - `cover_image` column to `communities` table
   - New `community_join_requests` table
   - Necessary indexes for performance

2. **Create Storage Buckets**
   
   In Supabase Dashboard, create these storage buckets:
   - `chat-image` - For message images (public)
   - `community` - For community avatars and covers (public)

   Bucket settings:
   - Public: Yes
   - File size limit: 10MB (recommended)
   - Allowed MIME types: `image/jpeg`, `image/png`, `image/jpg`

3. **Update Environment Variables**
   
   Update your `.env` file:
   ```env
   MESSAGES_BUCKET=chat-image
   COMMUNITY_BUCKET=community
   ```

## 📡 API Changes

### New Endpoints

#### Community Admin Management

**Update Member Role**
```http
POST /communities/:id/members/:username/role
Body: { actor: string, role: 'admin' | 'moderator' | 'member' }
```

**Kick Member**
```http
DELETE /communities/:id/members/:username
Body: { actor: string }
```

**Upload Avatar**
```http
POST /communities/:id/avatar
FormData: { actor: string, avatar: File }
```

**Upload Cover**
```http
POST /communities/:id/cover
FormData: { actor: string, cover: File }
```

#### Join Request Management

**Send Join Request**
```http
POST /communities/:id/join-request
Body: { username: string }
```

**Get Join Requests** (admin only)
```http
GET /communities/:id/join-requests?actor=<username>&status=pending
```

**Review Join Request** (admin only)
```http
POST /communities/:id/join-requests/:requestId
Body: { actor: string, action: 'approve' | 'reject' }
```

#### Community Chat

**Get Chat Messages**
```http
GET /communities/:id/chat/messages?viewer=<username>&limit=50
```

### Modified Endpoints

**Create Community** - Now requires PRO user
```http
POST /communities
Body: { created_by: string, name: string, description?: string, image_url?: string, is_private?: boolean }
Response (if not PRO): { message: string, requiresPro: true }
```

**Join Community** - Blocks private communities
```http
POST /communities/:id/join
Body: { username: string }
Response (if private): { message: string, requiresRequest: true }
```

### Removed Endpoints

All video/voice calling WebSocket events have been removed:
- `initiate_call`
- `accept_call`
- `reject_call`
- `end_call`
- `upgrade_to_video`
- `video_upgrade_accepted`
- `call_timeout`

## 🔌 WebSocket Events

### New Community Chat Events

**Join Community Chat**
```javascript
socket.emit('join_community_chat', { communityId: number })
```

**Leave Community Chat**
```javascript
socket.emit('leave_community_chat', { communityId: number })
```

**Send Community Message**
```javascript
socket.emit('send_community_message', {
  communityId: number,
  senderUsername: string,
  content: string
})
```

**Listen for New Messages**
```javascript
socket.on('new_community_message', (message) => {
  // message format:
  // {
  //   id, conversation_id, sender_username, content, created_at,
  //   communityId, chatId, senderId, timestamp,
  //   sender: { username, name, avatar, ... }
  // }
})
```

**Typing Indicator**
```javascript
socket.emit('community_typing', {
  communityId: number,
  username: string,
  isTyping: boolean
})

socket.on('community_typing', ({ communityId, username, isTyping }) => {
  // Handle typing indicator
})
```

## 🧪 Testing Checklist

### PRO User Restriction
- [ ] Non-PRO user tries to create community → Gets error with `requiresPro: true`
- [ ] PRO user creates community → Success
- [ ] Community conversation is auto-created

### Private Community Join Requests
- [ ] User tries to join private community directly → Gets error with `requiresRequest: true`
- [ ] User sends join request → Request created with `pending` status
- [ ] Admin views pending requests → List of requests shown
- [ ] Admin approves request → User added to members
- [ ] Admin rejects request → Request marked as rejected

### Community Admin Features
- [ ] Admin uploads avatar → Image saved to `community` bucket
- [ ] Admin uploads cover → Cover image updated
- [ ] Admin promotes member to moderator → Role updated
- [ ] Admin kicks member → Member removed, count updated
- [ ] Non-admin tries admin action → 403 Forbidden

### Community Chat
- [ ] User joins community chat → Socket joins room
- [ ] User sends message → Message saved and broadcast
- [ ] Other members receive message → Real-time delivery
- [ ] User leaves chat → Socket leaves room
- [ ] Typing indicators work → Other members see typing status

### Image Sending in Messages
- [ ] User sends image in conversation → Image uploads to `chat-image` bucket
- [ ] Image displays correctly in chat → Public URL works
- [ ] Multiple images can be sent → Media array populated

## 🔧 Troubleshooting

### Community Chat Not Working
1. Check if conversation was created for the community
2. Verify WebSocket connection is established
3. Check if user is a member of the community

### Join Request Not Working
1. Verify community is marked as `is_private: true`
2. Check `community_join_requests` table exists
3. Ensure admin has proper permissions

### Image Upload Failing
1. Verify storage buckets exist in Supabase:
   - `chat-image` for messages
   - `community` for community images
2. Check bucket permissions are set to public
3. Verify file size is under 10MB

### PRO Restriction Not Working
1. Check user's `is_premium` field in database
2. Verify JWT token contains correct user info

## 📚 Additional Resources

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Socket.IO Documentation](https://socket.io/docs/v4/)
- [Express.js Multer Guide](https://github.com/expressjs/multer)

## 🤝 Support

If you encounter any issues, please:
1. Check the server logs for error messages
2. Verify all migration steps were completed
3. Test with the Postman collection provided
4. Check the client repository for matching implementation
