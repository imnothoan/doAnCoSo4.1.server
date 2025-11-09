# Server-Client Synchronization Guide

This document explains how the ConnectSphere server (this repository) synchronizes with the React Native client app at https://github.com/imnothoan/doAnCoSo4.1

## Overview

The server provides a complete RESTful API that supports all features required by the UniVini-like mobile app. The client makes HTTP requests to these endpoints and manages the UI/UX layer.

## Architecture

```
┌─────────────────────────────────────────┐
│   React Native Client (Expo)            │
│   - UI Components                       │
│   - State Management (Redux/Context)    │
│   - Navigation                          │
│   - API Client (Axios)                  │
└──────────────┬──────────────────────────┘
               │ HTTP/REST API
               ▼
┌─────────────────────────────────────────┐
│   Express.js Server (This Repo)         │
│   - Route Handlers                      │
│   - Business Logic                      │
│   - File Upload (Multer)                │
│   - Authentication Middleware           │
└──────────────┬──────────────────────────┘
               │ Supabase Client
               ▼
┌─────────────────────────────────────────┐
│   Supabase (PostgreSQL + Storage)       │
│   - Database Tables                     │
│   - File Storage (Avatars, Posts, etc)  │
│   - Real-time Subscriptions (optional)  │
└─────────────────────────────────────────┘
```

## Feature Mapping

### 1. Hang Out Tab

**Client Requirements:**
- Toggle "Available to hang out now"
- Select activities (drink tea, grab beers, etc.)
- Filter by languages and distance
- View open hangouts and my hangouts
- Show meeting points with real-time locations

**Server Endpoints:**
```javascript
// Update availability
PUT /hangouts/status
Body: { username, is_available, current_activity, activities }

// Create hangout
POST /hangouts
Body: { creator_username, title, activities, languages, latitude, longitude }

// Get filtered hangouts
GET /hangouts?languages=English,Vietnamese&distance_km=10&user_lat=10.7&user_lng=106.7

// Get connection history
GET /hangouts/connections/:username

// Join hangout
POST /hangouts/:id/join
```

**Data Flow:**
1. Client updates user's hangout status → Server stores in `user_hangout_status` table
2. Client requests nearby hangouts → Server queries with distance calculation → Returns sorted results
3. Client joins hangout → Server creates participant record → Returns updated hangout
4. Client creates connection → Server stores in `hangout_connections` with locations

### 2. My Events Tab

**Client Requirements:**
- List events with distance, name, date, address
- View event details with participants, comments
- Join/leave events
- Add comments with images
- Invite friends

**Server Endpoints:**
```javascript
// Get user's events
GET /events/user/:username/participating
GET /events/user/:username/created

// Get all events with distance
GET /events?status=upcoming&distance_km=10&user_lat=10.7&user_lng=106.7

// Event details
GET /events/:id?viewer=username

// Participate
POST /events/:id/participate
Body: { username, status: 'going' | 'interested' }

// Add comment
POST /events/:id/comments
FormData: { author_username, content, image }

// Invite friends
POST /events/:id/invite
Body: { inviter_username, invitee_usernames: [] }
```

**Data Flow:**
1. Client fetches events → Server calculates distances → Returns sorted by distance
2. Client views event → Server returns full details with participants and comments
3. Client joins event → Server creates `event_participants` record → Updates counts
4. Client adds comment → Server uploads image to storage → Creates comment record

### 3. Notification

**Client Requirements:**
- Show notification list
- Display unread count
- Mark as read
- Different notification types (follow, event, message, etc.)

**Server Endpoints:**
```javascript
// Get notifications
GET /notifications?username=johndoe&limit=50&unread_only=false

// Unread count
GET /notifications/unread-count?username=johndoe

// Mark as read
PUT /notifications/mark-read
Body: { username, notification_ids: [1,2,3] } or { username, all: true }
```

**Data Flow:**
1. Server creates notifications when actions occur (follow, event invite, etc.)
2. Client polls for new notifications or subscribes to real-time updates
3. Client displays notifications with appropriate icons/messages
4. User taps notification → Client marks as read → Server updates `is_read` field

### 4. Discussion Tab

**Client Requirements:**
- Search communities
- Suggested communities
- Upload to communities (posts)
- Like and comment on posts

**Server Endpoints:**
```javascript
// Search/get communities
GET /communities?q=language
GET /communities/suggested?limit=10

// Join community
POST /communities/:id/join

// Create post
POST /communities/:id/posts
FormData: { author_username, content, image }

// Like/unlike
POST /communities/:id/posts/:postId/like
DELETE /communities/:id/posts/:postId/like

// Comment
POST /communities/:id/posts/:postId/comments
Body: { author_username, content, parent_id }
```

**Data Flow:**
1. Client searches → Server queries communities → Returns with member/post counts
2. Client creates post → Server uploads image → Creates post record → Increments post count
3. Client likes post → Server creates like record → Updates like count
4. Client adds comment → Server creates comment → Updates comment count

### 5. Connection Tab

**Client Requirements:**
- List all users
- Search by name
- Filter by gender, age, distance
- View user profiles
- Event cards with search and filters

**Server Endpoints:**
```javascript
// Search users
GET /users/search?q=john

// Get user profile
GET /users/username/:username

// Follow/unfollow
POST /users/:username/follow
DELETE /users/:username/follow

// Get all events (for discovery)
GET /events?status=upcoming&distance_km=20

// Get followers/following
GET /users/:username/followers?viewer=currentUser
GET /users/:username/following?viewer=currentUser
```

**Data Flow:**
1. Client gets user list → Server returns users (can add filtering later)
2. Client searches → Server queries by username/name
3. Client views profile → Server returns full profile with stats
4. Client filters events → Server applies filters and returns results

### 6. Inbox Tab

**Client Requirements:**
- Event chats (group conversations)
- User-to-user chats
- Quick messages (/x shortcut)
- Send text and media messages

**Server Endpoints:**
```javascript
// Get conversations
GET /messages/conversations?user=johndoe

// Get messages
GET /messages/conversations/:id/messages?limit=30&before=timestamp

// Send text
POST /messages/conversations/:id/messages
Body: { sender_username, content, reply_to_message_id }

// Send media
POST /messages/conversations/:id/messages/media
FormData: { sender_username, content, files }

// Quick messages
GET /quick-messages?username=johndoe
POST /quick-messages
Body: { username, shortcut: '/x', message: 'Xin chào' }
GET /quick-messages/expand?username=johndoe&shortcut=/x
```

**Data Flow:**
1. Client loads inbox → Server returns conversations with last message and unread count
2. Client opens conversation → Server returns paginated messages
3. Client sends message → Server creates message record → Increments unread for recipients
4. Client uses quick message → Server expands shortcut → Client sends expanded message

### 7. Account Tab

**Client Requirements:**
- View profile card
- Edit profile
- Profile completion progress
- Languages, interests, countries
- Settings and sign out

**Server Endpoints:**
```javascript
// Get profile
GET /users/username/:username

// Update profile
PUT /users/:id
Body: { name, bio, status, country, city, interests, ... }

// Profile completion
GET /users/:username/profile-completion

// Languages
GET /users/:username/languages
POST /users/:username/languages

// Countries
GET /users/:username/countries
POST /users/:username/countries

// Upload avatar
POST /users/upload-avatar
FormData: { avatar }
Query: ?id=user_id
```

**Data Flow:**
1. Client displays profile → Server returns full user data with stats
2. Client edits profile → Server validates and updates → Returns updated data
3. Client checks completion → Server calculates based on filled fields → Returns percentage
4. Client uploads avatar → Server stores in Supabase Storage → Updates user record

## Real-time Features

For real-time updates, you can implement:

### Option 1: Polling
Client periodically calls endpoints to check for updates:
- Notifications: Poll every 30 seconds
- Messages: Poll when conversation is open
- Online status: Update every 5 minutes

### Option 2: Supabase Real-time (Recommended)
Use Supabase's real-time subscriptions:

```javascript
// Client subscribes to new messages
const subscription = supabase
  .from('messages')
  .on('INSERT', payload => {
    // Update UI with new message
  })
  .subscribe()
```

The server doesn't need changes for this - Supabase handles it automatically.

## Authentication Flow

1. **Client Login:**
   - User signs in with Supabase Auth (email/password, OAuth, etc.)
   - Supabase returns auth token and user ID
   - Client stores token securely

2. **API Requests:**
   - Client includes token in request headers
   - Server validates token with Supabase
   - Server processes request with authenticated user

3. **Profile Creation:**
   - After first login, client calls `POST /users/create-profile`
   - Server creates user record in database
   - Client can now use all features

## Location Handling

**Client Responsibilities:**
- Request location permissions
- Get user's current location (latitude/longitude)
- Update location periodically when online
- Include location in API requests for distance filtering

**Server Responsibilities:**
- Store user locations in database
- Calculate distances using Haversine formula
- Filter results by distance
- Return distance in API responses

Example:
```javascript
// Client gets location
const { latitude, longitude } = await Location.getCurrentPositionAsync();

// Client updates profile
await api.put('/users/:id', { latitude, longitude, is_online: true });

// Client searches events
const events = await api.get('/events', {
  params: {
    user_lat: latitude,
    user_lng: longitude,
    distance_km: 10
  }
});
// events now include distance field
```

## File Upload Flow

1. **Client selects image/video**
2. **Client sends multipart/form-data request**
3. **Server receives file via Multer**
4. **Server uploads to Supabase Storage**
5. **Server gets public URL**
6. **Server stores URL in database**
7. **Server returns URL to client**
8. **Client displays image from URL**

Supported buckets:
- `avatars` - User profile pictures
- `posts` - Post images/videos
- `messages` - Message attachments

## Error Handling

**Server responses:**
```javascript
// Success
{ data: {...} }

// Error
{ message: "Error description" }
```

**Client should handle:**
- Network errors (timeout, no connection)
- Authentication errors (401 → redirect to login)
- Validation errors (400 → show to user)
- Server errors (500 → show generic error, retry)

## Testing Synchronization

1. **Import Postman collection** (`ConnectSphere.postman_collection.json`)
2. **Set up test user:**
   ```json
   POST /users/create-profile
   {
     "id": "test-uuid",
     "email": "test@example.com",
     "username": "testuser",
     "name": "Test User"
   }
   ```
3. **Test each feature:**
   - Create event → Join event → Add comment
   - Update hangout status → Create hangout → Join
   - Create community → Post → Like → Comment
   - Send message → Mark as read
   - etc.

4. **Verify in client app:**
   - Data appears correctly
   - Updates reflect immediately
   - Images load properly
   - Distance calculations are accurate

## Performance Optimization

**Server:**
- ✅ Database indexes on frequently queried fields
- ✅ Pagination for large lists
- ✅ Limit query results (max 100)
- ✅ Efficient SQL queries with proper joins
- Future: Caching for frequently accessed data

**Client:**
- Implement data caching (Redux Persist)
- Lazy load images
- Paginate long lists
- Debounce search inputs
- Prefetch data when possible

## Deployment Checklist

- [ ] Set up production Supabase project
- [ ] Run database schema
- [ ] Create storage buckets
- [ ] Configure environment variables
- [ ] Deploy server to hosting platform
- [ ] Update client API base URL
- [ ] Test all features end-to-end
- [ ] Enable HTTPS
- [ ] Set up monitoring and logging
- [ ] Configure CORS for production domains

## Support

For issues or questions:
- Server issues: Open issue in this repository
- Client issues: Open issue in client repository
- Database issues: Check Supabase dashboard logs
- API testing: Use provided Postman collection

---

**The server is fully implemented and ready for client integration!** 🚀

All endpoints are documented in `API_DOCS.md` and ready to use. The client can now be built to consume these APIs and provide the full UniVini-like experience.
