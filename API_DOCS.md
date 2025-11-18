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

## Payment & Subscription Endpoints

### Get Available Plans

Get all available subscription plans (Free and Pro).

```http
GET /payments/plans
```

**Response:**
```json
{
  "plans": [
    {
      "id": "free",
      "name": "Free Plan",
      "price": 0,
      "currency": "VND",
      "features": [
        "16 friends limit",
        "Basic messaging",
        "Standard theme (Blue)",
        "Event participation",
        "Community access"
      ],
      "max_friends": 16,
      "theme": "blue",
      "ai_enabled": false
    },
    {
      "id": "pro",
      "name": "Pro Plan",
      "price": 50000,
      "currency": "VND",
      "duration": "monthly",
      "features": [
        "512 friends limit",
        "Premium messaging",
        "Premium theme (Yellow)",
        "AI post writing assistant (coming soon)",
        "Priority event access",
        "Ad-free experience"
      ],
      "max_friends": 512,
      "theme": "yellow",
      "ai_enabled": true
    }
  ]
}
```

### Get User Subscription

Get the current subscription status for a user.

```http
GET /payments/subscription?username=johndoe
```

**Response:**
```json
{
  "id": 1,
  "username": "johndoe",
  "plan_type": "pro",
  "status": "active",
  "start_date": "2025-01-01T00:00:00Z",
  "end_date": "2025-02-01T00:00:00Z",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

### Subscribe to Pro Plan

Subscribe to the Pro plan (test payment - no real money).

```http
POST /payments/subscribe
Content-Type: application/json

{
  "username": "johndoe",
  "plan_type": "pro",
  "payment_method": "test"
}
```

**Response:**
```json
{
  "subscription": {
    "id": 1,
    "username": "johndoe",
    "plan_type": "pro",
    "status": "active",
    "start_date": "2025-01-01T00:00:00Z",
    "end_date": "2025-02-01T00:00:00Z"
  },
  "transaction": {
    "id": 1,
    "username": "johndoe",
    "amount": 50000,
    "currency": "VND",
    "plan_type": "pro",
    "status": "completed",
    "payment_method": "test",
    "transaction_date": "2025-01-01T00:00:00Z"
  },
  "message": "Successfully subscribed to Pro plan!"
}
```

**Effects:**
- User's `is_premium` set to `true`
- User's `max_friends` increased to 512
- User's `theme_preference` changed to "yellow"
- Subscription valid for 1 month from purchase date

### Cancel Subscription

Cancel the current subscription and downgrade to Free plan.

```http
POST /payments/cancel
Content-Type: application/json

{
  "username": "johndoe"
}
```

**Response:**
```json
{
  "subscription": {
    "id": 1,
    "username": "johndoe",
    "plan_type": "free",
    "status": "cancelled",
    "end_date": "2025-01-15T00:00:00Z"
  },
  "message": "Subscription cancelled. Downgraded to Free plan."
}
```

**Effects:**
- User's `is_premium` set to `false`
- User's `max_friends` reduced to 16
- User's `theme_preference` changed to "blue"

### Get Payment History

Get all payment transactions for a user.

```http
GET /payments/history?username=johndoe
```

**Response:**
```json
[
  {
    "id": 1,
    "username": "johndoe",
    "amount": 50000,
    "currency": "VND",
    "plan_type": "pro",
    "status": "completed",
    "payment_method": "test",
    "transaction_date": "2025-01-01T00:00:00Z",
    "created_at": "2025-01-01T00:00:00Z"
  }
]
```

---

## Follow & Connection Endpoints

### Check Mutual Follow Status

Check if two users mutually follow each other (required for voice/video calling).

```http
GET /users/:username/mutual-follow/:otherUsername
```

**Example:**
```http
GET /users/johndoe/mutual-follow/janedoe
```

**Response:**
```json
{
  "isMutualFollow": true,
  "user1FollowsUser2": true,
  "user2FollowsUser1": true
}
```

**Use Case:**
- Client uses this to show/hide voice/video call buttons
- Only users who mutually follow each other can initiate calls
- Server validates mutual follow before allowing calls

---

## Post Endpoints

### Get Posts Feed

Get a feed of posts with author information.

```http
GET /posts?limit=20&before=2025-01-15T12:00:00Z
```

**Query Parameters:**
- `limit` (optional) - Number of posts to return (default: 20, max: 100)
- `before` (optional) - ISO timestamp for cursor-based pagination

**Response:**
```json
[
  {
    "id": 123,
    "author_username": "johndoe",
    "authorAvatar": "https://example.com/avatar.jpg",
    "authorDisplayName": "John Doe",
    "content": "Hello world!",
    "status": "published",
    "audience": "public",
    "disable_comments": false,
    "hide_like_count": false,
    "like_count": 42,
    "comment_count": 5,
    "community_id": null,
    "created_at": "2025-01-15T12:00:00Z",
    "updated_at": "2025-01-15T12:00:00Z",
    "post_media": [
      {
        "id": 1,
        "post_id": 123,
        "media_url": "https://example.com/image.jpg",
        "media_type": "image",
        "position": 0
      }
    ]
  }
]
```

### Get Post by ID

Get a single post with author information and like status.

```http
GET /posts/:id?viewer=username
```

**Example:**
```http
GET /posts/123?viewer=johndoe
```

**Response:**
```json
{
  "id": 123,
  "author_username": "janedoe",
  "authorAvatar": "https://example.com/avatar.jpg",
  "authorDisplayName": "Jane Doe",
  "content": "Beautiful sunset today!",
  "status": "published",
  "like_count": 15,
  "comment_count": 3,
  "created_at": "2025-01-15T18:30:00Z",
  "isLikedByViewer": true,
  "post_media": [],
  "community_id": null
}
```

---

## WebSocket Events

### Connection

Connect to WebSocket server with authentication:

```javascript
import { io } from 'socket.io-client';

const socket = io('http://localhost:3000', {
  auth: {
    token: userAuthToken, // Base64 encoded userId:timestamp
  },
  transports: ['websocket', 'polling']
});
```

### Message Events

**Client Sends:**
- `send_message` - Send a message (data: conversationId, senderUsername, content, replyToMessageId)
- `join_conversation` - Join a conversation room (data: conversationId)
- `leave_conversation` - Leave a conversation room (data: conversationId)
- `typing` - Typing indicator (data: conversationId, username, isTyping)
- `mark_read` - Mark messages as read (data: conversationId, username, upToMessageId)
- `heartbeat_ack` - Acknowledge server heartbeat (sent automatically every 25s)

**Server Emits:**
- `message_sent` - Confirmation to sender that message was saved (to sender only)
- `new_message` - New message received (broadcast to others in room)
- `typing` - Someone is typing (broadcast to others in room)
- `messages_read` - Messages marked as read (broadcast to room)
- `user_status` - User online/offline status changed (broadcast to all)
- `heartbeat` - Server heartbeat (every 30s)
- `error` - Error message (to specific client)

### Voice/Video Calling Events

**Client Sends:**

1. **Initiate Call**
```javascript
socket.emit('initiate_call', {
  callId: 'call_1234567890_johndoe_janedoe',
  callerId: 'johndoe',
  callerName: 'John Doe',
  callerAvatar: 'https://example.com/avatar.jpg',
  receiverId: 'janedoe',
  callType: 'video', // or 'voice'
  timestamp: '2025-01-15T12:00:00Z'
});
```

2. **Accept Call**
```javascript
socket.emit('accept_call', {
  callId: 'call_1234567890_johndoe_janedoe',
  acceptedBy: 'janedoe'
});
```

3. **Reject Call**
```javascript
socket.emit('reject_call', {
  callId: 'call_1234567890_johndoe_janedoe',
  rejectedBy: 'janedoe'
});
```

4. **End Call**
```javascript
socket.emit('end_call', {
  callId: 'call_1234567890_johndoe_janedoe',
  endedBy: 'johndoe' // or 'janedoe'
});
```

**Server Emits:**

1. **Incoming Call** (to receiver)
```javascript
socket.on('incoming_call', (callData) => {
  // Show incoming call modal
  // callData: { callId, callerId, callerName, callerAvatar, receiverId, callType, timestamp }
});
```

2. **Call Accepted** (to caller)
```javascript
socket.on('call_accepted', (data) => {
  // Start call connection
  // data: { callId, acceptedBy }
});
```

3. **Call Rejected** (to caller)
```javascript
socket.on('call_rejected', (data) => {
  // Show rejection message
  // data: { callId, rejectedBy }
});
```

4. **Call Ended** (to other party)
```javascript
socket.on('call_ended', (data) => {
  // End call and return to previous screen
  // data: { callId, endedBy }
});
```

**Calling Security & Rules:**

- **Mutual Follow Required**: Both users must follow each other to initiate calls
- Server validates mutual follow before forwarding call
- Only online users can receive calls
- If receiver is offline, caller receives error
- CallId format: `call_{timestamp}_{callerId}_{receiverId}`

**Error Codes:**

```javascript
socket.on('error', (error) => {
  // error.code can be:
  // - 'NOT_MUTUAL_FOLLOW': Users don't mutually follow each other
  // - 'USER_OFFLINE': Receiver is not online
  // error.message contains human-readable description
});
```

**Example Call Flow:**

```javascript
// 1. Client checks mutual follow (optional but recommended for UX)
const { isMutualFollow } = await api.get('/users/johndoe/mutual-follow/janedoe');
if (!isMutualFollow) {
  // Show "You must be mutual friends to call"
  return;
}

// 2. Initiate call
socket.emit('initiate_call', callData);

// 3. Receiver gets incoming_call event
socket.on('incoming_call', (callData) => {
  showIncomingCallModal(callData);
});

// 4. Receiver accepts
socket.emit('accept_call', { callId, acceptedBy: 'janedoe' });

// 5. Caller gets call_accepted event
socket.on('call_accepted', (data) => {
  startWebRTCConnection(); // Start actual audio/video connection
});

// 6. Either party ends call
socket.emit('end_call', { callId, endedBy: currentUsername });

// 7. Other party gets call_ended event
socket.on('call_ended', (data) => {
  closeCallScreen();
});
```

---

## Notes

1. All timestamps are in ISO 8601 format (UTC)
2. File uploads use multipart/form-data
3. Arrays in JSON should be properly formatted
4. Empty arrays are valid for optional array fields
5. Null values are allowed for optional fields
6. WebSocket connection auto-updates user online status
7. Messages sent via WebSocket are also saved to database for persistence
8. **Payment system is for testing only** - no real money is charged
9. Subscriptions are monthly and do not auto-renew
10. Conversation endpoint now includes `other_participant` field for DM conversations with name and avatar
11. **Voice/Video calling requires mutual follow** - both users must follow each other
12. **Post endpoints include author info** - `authorAvatar` and `authorDisplayName` for display
13. **Call IDs must be unique** - Use format `call_{timestamp}_{callerId}_{receiverId}`
14. **WebRTC not included** - Server only handles signaling, actual media connection via WebRTC (client-side)
