# ConnectSphere API Documentation

Complete API reference for the ConnectSphere backend server.

## Base URL

```
http://localhost:3000
```

For production: Replace with your deployed server URL.

## Authentication

The API uses Supabase authentication. Include the user's auth token in requests where authentication is required.

## Common Response Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Missing or invalid parameters
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource conflict (e.g., duplicate)
- `500 Internal Server Error` - Server error

---

## User Endpoints

### Create or Update User Profile

```http
POST /users/create-profile
Content-Type: application/json

{
  "id": "uuid",
  "email": "user@example.com",
  "username": "johndoe",
  "name": "John Doe",
  "gender": "Male",
  "bio": "Love traveling and meeting new people",
  "avatar": "https://..."
}
```

### Get User by Username

```http
GET /users/username/:username

Response:
{
  "id": "uuid",
  "username": "johndoe",
  "name": "John Doe",
  "email": "user@example.com",
  "avatar": "https://...",
  "bio": "...",
  "country": "Vietnam",
  "city": "Ho Chi Minh",
  "status": "Open to Chat",
  "followers": 15,
  "following": 23,
  "posts": 42
}
```

### Update User Profile

```http
PUT /users/:id
Content-Type: application/json

{
  "name": "John Doe",
  "status": "Traveling",
  "country": "Vietnam",
  "city": "Hanoi",
  "interests": ["Language exchange", "Hiking"],
  "latitude": 21.0285,
  "longitude": 105.8542,
  "is_online": true
}
```

### Search Users

```http
GET /users/search?q=john

Response:
[
  {
    "id": "uuid",
    "username": "johndoe",
    "name": "John Doe",
    "avatar": "https://...",
    "bio": "..."
  }
]
```

### Follow/Unfollow User

```http
POST /users/:username/follow
Content-Type: application/json

{
  "followerUsername": "currentUser"
}

DELETE /users/:username/follow
Content-Type: application/json

{
  "followerUsername": "currentUser"
}
```

### Check Follow Status

```http
GET /users/:username/following/:followerUsername

Response:
{
  "isFollowing": true
}
```

### User Languages

```http
GET /users/:username/languages

POST /users/:username/languages
Content-Type: application/json

{
  "language": "English",
  "proficiency": "Fluent"
}

DELETE /users/:username/languages/:languageId
```

### User Countries

```http
GET /users/:username/countries?type=lived

POST /users/:username/countries
Content-Type: application/json

{
  "country": "Vietnam",
  "country_type": "lived"
}
```

### Profile Completion

```http
GET /users/:username/profile-completion

Response:
{
  "username": "johndoe",
  "completion_percentage": 75,
  "checklist": [
    { "item": "Add name", "completed": true },
    { "item": "Upload photo", "completed": true },
    { "item": "Confirm email", "completed": false }
  ]
}
```

---

## Event Endpoints

### Create Event

```http
POST /events
Content-Type: application/json

{
  "hosted_by": "johndoe",
  "name": "Garden by Bottega 5 - Connect & Chill",
  "description": "Weekly Friday night event",
  "details": "Join us for drinks, music, and great conversations...",
  "address": "123 Main St, District 1, Ho Chi Minh City",
  "latitude": 10.7769,
  "longitude": 106.7009,
  "date_start": "2025-11-07T19:30:00Z",
  "date_end": "2025-11-07T23:30:00Z",
  "entrance_fee": "Free",
  "schedule": "weekly 07:30 PM - 11:30 PM",
  "is_recurring": true,
  "recurrence_pattern": "weekly",
  "image_url": "https://..."
}
```

### Get Events (with filters)

```http
GET /events?status=upcoming&distance_km=10&user_lat=10.7769&user_lng=106.7009&limit=20

Response:
[
  {
    "id": 1,
    "name": "Garden by Bottega 5",
    "date_start": "2025-11-07T19:30:00Z",
    "address": "...",
    "hosted_by": "johndoe",
    "distance": 2.5,
    "participant_count": 15
  }
]
```

### Get Event Details

```http
GET /events/:id?viewer=currentUser

Response:
{
  "id": 1,
  "name": "Garden by Bottega 5",
  "description": "...",
  "participants": [
    { "username": "user1", "status": "going" }
  ],
  "participant_count": 15,
  "comment_count": 8,
  "viewer_status": "interested"
}
```

### Join Event

```http
POST /events/:id/participate
Content-Type: application/json

{
  "username": "johndoe",
  "status": "going"
}
```

### Invite to Event

```http
POST /events/:id/invite
Content-Type: application/json

{
  "inviter_username": "johndoe",
  "invitee_usernames": ["user1", "user2"]
}
```

### Add Event Comment

```http
POST /events/:id/comments
Content-Type: multipart/form-data

author_username: johndoe
content: Looking forward to this!
image: [file] (optional)
```

---

## Hangout Endpoints

### Update Hangout Status

```http
PUT /hangouts/status
Content-Type: application/json

{
  "username": "johndoe",
  "is_available": true,
  "current_activity": "grab beers",
  "activities": ["grab beers", "bar hopping", "get some food"]
}
```

### Get Hangout Status

```http
GET /hangouts/status/:username

Response:
{
  "username": "johndoe",
  "is_available": true,
  "current_activity": "grab beers",
  "activities": ["grab beers", "bar hopping"]
}
```

### Create Hangout

```http
POST /hangouts
Content-Type: application/json

{
  "creator_username": "johndoe",
  "title": "Beers in District 1",
  "description": "Looking for people to grab beers",
  "activities": ["grab beers", "bar hopping"],
  "languages": ["English", "Vietnamese"],
  "latitude": 10.7769,
  "longitude": 106.7009,
  "max_distance_km": 5
}
```

### Get Open Hangouts (with filters)

```http
GET /hangouts?languages=English,Vietnamese&distance_km=10&user_lat=10.7769&user_lng=106.7009

Response:
[
  {
    "id": 1,
    "title": "Beers in District 1",
    "creator_username": "johndoe",
    "activities": ["grab beers"],
    "languages": ["English", "Vietnamese"],
    "distance": 3.2,
    "status": "open"
  }
]
```

### Join Hangout

```http
POST /hangouts/:id/join
Content-Type: application/json

{
  "username": "currentUser"
}
```

### Get Hangout Connections History

```http
GET /hangouts/connections/:username?limit=20

Response:
[
  {
    "id": 1,
    "user1_username": "johndoe",
    "user2_username": "jane",
    "connection_date": "2025-11-01T10:00:00Z",
    "other_user": {
      "username": "jane",
      "name": "Jane Smith",
      "avatar": "https://..."
    }
  }
]
```

---

## Community Endpoints

### Create Community

```http
POST /communities
Content-Type: application/json

{
  "created_by": "johndoe",
  "name": "Language Exchange HCMC",
  "description": "Practice languages with native speakers",
  "image_url": "https://...",
  "is_private": false
}
```

### Get Suggested Communities

```http
GET /communities/suggested?limit=10

Response:
[
  {
    "id": 1,
    "name": "Language Exchange HCMC",
    "description": "...",
    "member_count": 234,
    "post_count": 89
  }
]
```

### Search Communities

```http
GET /communities?q=language&limit=20
```

### Join Community

```http
POST /communities/:id/join
Content-Type: application/json

{
  "username": "johndoe"
}
```

### Create Community Post

```http
POST /communities/:id/posts
Content-Type: multipart/form-data

author_username: johndoe
content: What's everyone learning this week?
image: [file] (optional)
```

### Like/Unlike Community Post

```http
POST /communities/:id/posts/:postId/like
Content-Type: application/json

{
  "username": "johndoe"
}

DELETE /communities/:id/posts/:postId/like
Content-Type: application/json

{
  "username": "johndoe"
}
```

### Add Comment to Community Post

```http
POST /communities/:id/posts/:postId/comments
Content-Type: application/json

{
  "author_username": "johndoe",
  "content": "Great question!",
  "parent_id": null
}
```

---

## Notification Endpoints

### Get Notifications

```http
GET /notifications?username=johndoe&limit=50&unread_only=false

Response:
[
  {
    "id": 1,
    "recipient_username": "johndoe",
    "sender_username": "jane",
    "type": "follow",
    "title": "New Follower",
    "content": "jane started following you",
    "is_read": false,
    "created_at": "2025-11-01T10:00:00Z"
  }
]
```

### Get Unread Count

```http
GET /notifications/unread-count?username=johndoe

Response:
{
  "username": "johndoe",
  "unread_count": 5
}
```

### Mark as Read

```http
PUT /notifications/mark-read
Content-Type: application/json

{
  "username": "johndoe",
  "notification_ids": [1, 2, 3]
}

// Or mark all as read:
{
  "username": "johndoe",
  "all": true
}
```

---

## Quick Message Endpoints

### Get Quick Messages

```http
GET /quick-messages?username=johndoe

Response:
[
  {
    "id": 1,
    "username": "johndoe",
    "shortcut": "/x",
    "message": "Xin chào"
  }
]
```

### Create Quick Message

```http
POST /quick-messages
Content-Type: application/json

{
  "username": "johndoe",
  "shortcut": "/x",
  "message": "Xin chào"
}
```

### Expand Shortcut

```http
GET /quick-messages/expand?username=johndoe&shortcut=/x

Response:
{
  "id": 1,
  "shortcut": "/x",
  "message": "Xin chào"
}
```

---

## Message Endpoints

### Create Conversation

```http
POST /messages/conversations
Content-Type: application/json

{
  "type": "dm",
  "created_by": "johndoe",
  "members": ["jane", "bob"]
}
```

### Get Conversations

```http
GET /messages/conversations?user=johndoe

Response:
[
  {
    "id": 1,
    "type": "dm",
    "title": null,
    "last_message": {
      "content": "Hey!",
      "created_at": "2025-11-01T10:00:00Z"
    },
    "unread_count": 2
  }
]
```

### Send Text Message

```http
POST /messages/conversations/:id/messages
Content-Type: application/json

{
  "sender_username": "johndoe",
  "content": "Hello!",
  "reply_to_message_id": null
}
```

### Send Media Message

```http
POST /messages/conversations/:id/messages/media
Content-Type: multipart/form-data

sender_username: johndoe
content: Check this out!
files: [file1, file2]
```

### Mark Messages as Read

```http
POST /messages/conversations/:id/read
Content-Type: application/json

{
  "username": "johndoe",
  "up_to_message_id": 123
}
```

---

## WebSocket Real-Time Events

The server supports real-time features via WebSocket (Socket.IO) for instant messaging, typing indicators, and user presence.

### Connection

```javascript
import io from 'socket.io-client';

const socket = io('http://localhost:3000', {
  auth: {
    token: '<user-auth-token>' // base64 encoded userId:timestamp
  },
  transports: ['websocket']
});
```

### Events to Emit (Client → Server)

#### join_conversation
Join a conversation room to receive real-time messages.
```javascript
socket.emit('join_conversation', {
  conversationId: '123'
});
```

#### leave_conversation
Leave a conversation room.
```javascript
socket.emit('leave_conversation', {
  conversationId: '123'
});
```

#### send_message
Send a message in real-time.
```javascript
socket.emit('send_message', {
  conversationId: '123',
  senderUsername: 'johndoe',
  content: 'Hello!',
  replyToMessageId: null // optional
});
```

#### typing
Notify others that you are typing.
```javascript
socket.emit('typing', {
  conversationId: '123',
  username: 'johndoe',
  isTyping: true // or false when stopped
});
```

#### mark_read
Mark messages as read up to a certain message ID.
```javascript
socket.emit('mark_read', {
  conversationId: '123',
  username: 'johndoe',
  upToMessageId: 456
});
```

### Events to Listen (Server → Client)

#### new_message
Receive a new message in a conversation you've joined.
```javascript
socket.on('new_message', (message) => {
  console.log('New message:', message);
  // message: { id, conversation_id, sender_username, content, created_at, ... }
});
```

#### typing
Receive typing indicator from other users.
```javascript
socket.on('typing', (data) => {
  console.log(`${data.username} is typing:`, data.isTyping);
  // data: { conversationId, username, isTyping }
});
```

#### messages_read
Notified when someone reads messages.
```javascript
socket.on('messages_read', (data) => {
  console.log(`${data.username} read up to message ${data.upToMessageId}`);
  // data: { conversationId, username, upToMessageId }
});
```

#### user_status
Receive online/offline status updates.
```javascript
socket.on('user_status', (data) => {
  console.log(`${data.username} is ${data.isOnline ? 'online' : 'offline'}`);
  // data: { username, isOnline }
});
```

#### error
Receive error messages.
```javascript
socket.on('error', (error) => {
  console.error('WebSocket error:', error.message);
});
```

### Connection Events

```javascript
socket.on('connect', () => {
  console.log('Connected to WebSocket');
});

socket.on('disconnect', (reason) => {
  console.log('Disconnected:', reason);
});

socket.on('connect_error', (error) => {
  console.error('Connection error:', error);
});
```

---

## Error Responses

All error responses follow this format:

```json
{
  "message": "Error description"
}
```

Common errors:
- Missing required fields
- Resource not found
- Unauthorized access
- Validation errors
- Server errors

---

## Pagination

Most list endpoints support pagination:

- `limit` - Number of results (default: 20, max: 100)
- `before` - ISO timestamp for cursor-based pagination
- `page` - Page number (where applicable)

---

## Distance Filtering

Endpoints that support location filtering:
- Events
- Hangouts

Parameters:
- `user_lat` - User's latitude
- `user_lng` - User's longitude
- `distance_km` - Maximum distance in kilometers

Distance is calculated using the Haversine formula and returned in the response.

---

## Notes

1. All timestamps are in ISO 8601 format (UTC)
2. File uploads use multipart/form-data
3. Arrays in JSON should be properly formatted
4. Empty arrays are valid for optional array fields
5. Null values are allowed for optional fields
6. WebSocket connection auto-updates user online status
7. Messages sent via WebSocket are also saved to database for persistence
