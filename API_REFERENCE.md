# Community Features API Reference

Quick reference guide for all community-related API endpoints.

## 🏘️ Community CRUD

### Create Community (PRO Only)
```http
POST /communities
Content-Type: application/json

{
  "created_by": "username",
  "name": "Community Name",
  "description": "Description (optional)",
  "image_url": "https://... (optional)",
  "is_private": false
}

Response 201:
{
  "id": 1,
  "name": "Community Name",
  "created_by": "username",
  "member_count": 1,
  "post_count": 0,
  "is_private": false,
  "created_at": "2024-01-01T00:00:00Z"
}

Response 403 (Non-PRO):
{
  "message": "Only PRO users can create communities.",
  "requiresPro": true
}
```

### Get All Communities
```http
GET /communities?q=search_term&limit=20

Response 200:
[
  {
    "id": 1,
    "name": "Community Name",
    "description": "...",
    "image_url": "...",
    "cover_image": "...",
    "created_by": "username",
    "member_count": 100,
    "post_count": 50,
    "is_private": false,
    "created_at": "...",
    "updated_at": "..."
  }
]
```

### Get Suggested Communities
```http
GET /communities/suggested?limit=10

Response 200: [array of communities sorted by member_count]
```

### Get Single Community
```http
GET /communities/:id?viewer=username

Response 200:
{
  "id": 1,
  "name": "...",
  "is_member": true,
  ...
}
```

### Update Community (Admin Only)
```http
PUT /communities/:id
Content-Type: application/json

{
  "actor": "admin_username",
  "name": "New Name (optional)",
  "description": "New Description (optional)",
  "image_url": "... (optional)",
  "is_private": true
}

Response 200: Updated community object
Response 403: Not admin
```

### Delete Community (Creator Only)
```http
DELETE /communities/:id
Content-Type: application/json

{
  "actor": "creator_username"
}

Response 200: { "message": "Community deleted." }
Response 403: Not creator
```

## 👥 Community Membership

### Join Community (Public Only)
```http
POST /communities/:id/join
Content-Type: application/json

{
  "username": "username"
}

Response 200: Member object
Response 403 (Private):
{
  "message": "Cannot join private community directly...",
  "requiresRequest": true
}
```

### Leave Community
```http
DELETE /communities/:id/join
Content-Type: application/json

{
  "username": "username"
}

Response 200: { "message": "Left community." }
```

### Get Community Members
```http
GET /communities/:id/members?limit=50

Response 200:
[
  {
    "username": "user1",
    "role": "admin",
    "joined_at": "...",
    "user": {
      "id": 1,
      "username": "user1",
      "name": "User One",
      "avatar": "...",
      "bio": "..."
    }
  }
]
```

### Get User's Communities
```http
GET /communities/user/:username/joined?limit=20

Response 200: [array of communities]
```

## 🛡️ Admin Management

### Update Member Role
```http
POST /communities/:id/members/:username/role
Content-Type: application/json

{
  "actor": "admin_username",
  "role": "admin" | "moderator" | "member"
}

Response 200: Updated member object
Response 403: Not admin
```

### Kick Member
```http
DELETE /communities/:id/members/:username
Content-Type: application/json

{
  "actor": "admin_username"
}

Response 200: { "message": "Member kicked successfully." }
Response 403: Not admin/moderator
Response 403: Cannot kick creator
```

### Upload Community Avatar
```http
POST /communities/:id/avatar
Content-Type: multipart/form-data

Form Fields:
- actor: admin_username
- avatar: [image file]

Response 200: Updated community with new image_url
Response 403: Not admin
```

### Upload Community Cover
```http
POST /communities/:id/cover
Content-Type: multipart/form-data

Form Fields:
- actor: admin_username
- cover: [image file]

Response 200: Updated community with new cover_image
Response 403: Not admin
```

## 🚪 Join Request System

### Request to Join Private Community
```http
POST /communities/:id/join-request
Content-Type: application/json

{
  "username": "username"
}

Response 201:
{
  "id": 1,
  "community_id": 1,
  "username": "username",
  "status": "pending",
  "created_at": "..."
}

Response 400: Not private / Already member
```

### Get Join Requests (Admin Only)
```http
GET /communities/:id/join-requests?actor=admin_username&status=pending

Response 200:
[
  {
    "id": 1,
    "community_id": 1,
    "username": "user1",
    "status": "pending",
    "created_at": "...",
    "user": {
      "username": "user1",
      "name": "User One",
      "avatar": "...",
      "bio": "..."
    }
  }
]

Response 403: Not admin
```

### Review Join Request (Admin Only)
```http
POST /communities/:id/join-requests/:requestId
Content-Type: application/json

{
  "actor": "admin_username",
  "action": "approve" | "reject"
}

Response 200: { "message": "Request approved." }
Response 403: Not admin
Response 400: Already reviewed
```

## 📝 Community Posts

### Create Post
```http
POST /communities/:id/posts
Content-Type: multipart/form-data

Form Fields:
- author_username: username
- content: Post content
- audience: "followers" (default)
- disable_comments: "false"
- hide_like_count: "false"
- image: [optional image file]

Response 201:
{
  "id": 1,
  "author_username": "username",
  "content": "...",
  "community_id": 1,
  "community_name": "...",
  "like_count": 0,
  "comment_count": 0,
  "post_media": [...],
  "author_avatar": "...",
  "author_display_name": "...",
  "created_at": "..."
}

Response 403: Not a member
```

### Get Community Posts
```http
GET /communities/:id/posts?limit=20&before=2024-01-01T00:00:00Z

Response 200: [array of posts with media and author info]
```

### Delete Post
```http
DELETE /communities/:id/posts/:postId
Content-Type: application/json

{
  "actor": "username"
}

Response 200: { "message": "Post deleted." }
Response 403: Not author/admin
```

## ❤️ Post Interactions

### Like Post
```http
POST /communities/:id/posts/:postId/like
Content-Type: application/json

{
  "username": "username"
}

Response 200: { "post_id": 1, "like_count": 5 }
```

### Unlike Post
```http
DELETE /communities/:id/posts/:postId/like
Content-Type: application/json

{
  "username": "username"
}

Response 200: { "post_id": 1, "like_count": 4 }
```

## 💬 Post Comments

### Add Comment
```http
POST /communities/:id/posts/:postId/comments
Content-Type: application/json

{
  "author_username": "username",
  "content": "Comment text",
  "parent_id": null | 123
}

Response 201: Comment object
```

### Get Comments
```http
GET /communities/:id/posts/:postId/comments?parent_id=null

Response 200: [array of comments]
```

### Get All Comments
```http
GET /communities/:id/posts/:postId/comments/all

Response 200: [array of all comments including replies]
```

### Delete Comment
```http
DELETE /communities/:id/posts/:postId/comments/:commentId
Content-Type: application/json

{
  "actor": "username"
}

Response 200: { "message": "Comment deleted." }
Response 403: Not author/admin
```

### Edit Comment
```http
PATCH /communities/:id/posts/:postId/comments/:commentId
Content-Type: application/json

{
  "actor": "username",
  "content": "Updated comment text"
}

Response 200: Updated comment object
Response 403: Not author/admin
```

## 💬 Community Chat

### Get Chat Messages
```http
GET /communities/:id/chat/messages?viewer=username&limit=50

Response 200:
[
  {
    "id": 1,
    "conversation_id": 123,
    "sender_username": "user1",
    "message_type": "text",
    "content": "Hello!",
    "created_at": "...",
    "sender": {
      "id": 1,
      "username": "user1",
      "name": "User One",
      "avatar": "...",
      ...
    }
  }
]

Response 403: Not a member
```

## 🔌 WebSocket Events

### Connection
```javascript
const socket = io('https://your-server.com', {
  auth: {
    token: base64Encode(`${userId}:${timestamp}`)
  }
});
```

### Join Community Chat
```javascript
socket.emit('join_community_chat', {
  communityId: 1
});

// Listen for join confirmation
socket.on('user_joined_community_chat', ({ communityId, username }) => {
  console.log(`${username} joined community ${communityId}`);
});
```

### Leave Community Chat
```javascript
socket.emit('leave_community_chat', {
  communityId: 1
});

// Listen for leave notification
socket.on('user_left_community_chat', ({ communityId, username }) => {
  console.log(`${username} left community ${communityId}`);
});
```

### Send Message
```javascript
socket.emit('send_community_message', {
  communityId: 1,
  senderUsername: 'username',
  content: 'Hello everyone!'
});
```

### Receive Messages
```javascript
socket.on('new_community_message', (message) => {
  console.log('New message:', message);
  // message format:
  // {
  //   id, conversation_id, sender_username, content, created_at,
  //   communityId, chatId, senderId, timestamp,
  //   sender: { username, name, avatar, ... }
  // }
});
```

### Typing Indicator
```javascript
// Send typing status
socket.emit('community_typing', {
  communityId: 1,
  username: 'username',
  isTyping: true
});

// Receive typing status
socket.on('community_typing', ({ communityId, username, isTyping }) => {
  console.log(`${username} is ${isTyping ? 'typing' : 'not typing'}`);
});
```

### Error Handling
```javascript
socket.on('error', ({ message }) => {
  console.error('Socket error:', message);
});
```

## 📨 Message Image Upload

### Send Message with Image
```http
POST /messages/conversations/:id/messages
Content-Type: multipart/form-data

Form Fields:
- sender_username: username
- content: Message text
- image: [image file]
- reply_to_message_id: [optional]

Response 201:
{
  "id": 1,
  "conversation_id": 1,
  "sender_username": "username",
  "message_type": "image",
  "content": "Check this out!",
  "created_at": "...",
  "message_media": [
    {
      "id": 1,
      "message_id": 1,
      "media_url": "https://.../chat-image/...",
      "media_type": "image",
      "position": 0
    }
  ]
}
```

## 🔐 Authorization

### Required Headers
```http
Authorization: Bearer [token]  (if using JWT)
Content-Type: application/json (for JSON requests)
Content-Type: multipart/form-data (for file uploads)
```

### Permission Levels

**Public** - No authentication required:
- Get communities list
- Get suggested communities
- Get single community (basic info)

**Member** - Must be community member:
- View community chat
- Create posts
- Like/comment on posts
- Join public communities

**Admin/Moderator** - Must have admin/moderator role:
- Update member roles
- Kick members
- Upload avatar/cover
- Review join requests
- Delete any posts/comments

**Creator** - Must be community creator:
- Delete community
- Transfer ownership (future)

## 📊 Error Responses

### 400 Bad Request
```json
{
  "message": "Missing required field"
}
```

### 403 Forbidden
```json
{
  "message": "Only admins can perform this action"
}

// Special cases:
{
  "message": "Only PRO users can create communities",
  "requiresPro": true
}

{
  "message": "Cannot join private community directly",
  "requiresRequest": true
}
```

### 404 Not Found
```json
{
  "message": "Community not found"
}
```

### 500 Server Error
```json
{
  "message": "Server error while processing request"
}
```

## 🧪 Testing Examples

### cURL Examples

```bash
# Create community (PRO user)
curl -X POST http://localhost:3000/communities \
  -H "Content-Type: application/json" \
  -d '{"created_by":"pro_user","name":"Test Community"}'

# Join public community
curl -X POST http://localhost:3000/communities/1/join \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user"}'

# Upload community avatar
curl -X POST http://localhost:3000/communities/1/avatar \
  -F "actor=admin_user" \
  -F "avatar=@avatar.jpg"

# Send message with image
curl -X POST http://localhost:3000/messages/conversations/1/messages \
  -F "sender_username=test_user" \
  -F "content=Check this!" \
  -F "image=@photo.jpg"
```

### JavaScript Examples

```javascript
// Create community
const response = await fetch('http://localhost:3000/communities', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    created_by: 'pro_user',
    name: 'Test Community',
    is_private: false
  })
});

// Upload avatar
const formData = new FormData();
formData.append('actor', 'admin_user');
formData.append('avatar', imageFile);

await fetch('http://localhost:3000/communities/1/avatar', {
  method: 'POST',
  body: formData
});
```

---

**Version:** 1.1.0  
**Last Updated:** 2024  
**Status:** Production Ready ✅
