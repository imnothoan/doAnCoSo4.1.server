# WebSocket Hangout Fix - Client Integration Guide

## Overview

This document explains the WebSocket improvements made to fix the Hangout (Tinder-like discovery) feature and how clients should integrate with the enhanced system.

## What Was Fixed

### Server-Side Changes

1. **Enhanced Authentication Logging**
   - Added emoji-based logging for better visibility (🔌 🔐 🔍 ✅ ❌)
   - Detailed logs for debugging authentication issues
   - Shows socketId, token presence, userId, and username

2. **Improved Online Status Updates**
   - Converted to async/await for better error handling
   - Explicit error checking for database operations
   - Broadcasts `user_status` event when users go online/offline

3. **Heartbeat Mechanism**
   - Server sends `heartbeat` event every 30 seconds
   - Maintains user's online status automatically
   - Updates `last_seen` timestamp on each heartbeat

4. **Enhanced Disconnect Handler**
   - Async handler with proper error handling
   - Clears heartbeat interval on disconnect
   - Properly sets `is_online = false` in database
   - Broadcasts offline status to other users

## Client Integration

### Required Changes

Add heartbeat response handler to your WebSocket service:

```typescript
// In your WebSocket service (e.g., src/services/websocket.ts)

connect(url: string, token?: string) {
  this.socket = io(url, {
    auth: {
      token,
    },
    transports: ['websocket', 'polling'],
  });

  // Add this listener to respond to server heartbeats
  this.socket.on('heartbeat', () => {
    this.socket?.emit('heartbeat_ack');
  });

  // Optional: Listen for user status changes
  this.socket.on('user_status', (data: { username: string; isOnline: boolean }) => {
    console.log(`User ${data.username} is now ${data.isOnline ? 'online' : 'offline'}`);
    // Update your UI or state management here
  });
}
```

### Optional Enhancements

#### 1. Track Online Users

```typescript
interface UserStatus {
  username: string;
  isOnline: boolean;
}

// In your service or store
private onlineUsers = new Set<string>();

setupUserStatusListener() {
  this.socket?.on('user_status', (data: UserStatus) => {
    if (data.isOnline) {
      this.onlineUsers.add(data.username);
    } else {
      this.onlineUsers.delete(data.username);
    }
    
    // Notify subscribers or update UI
    this.notifyStatusChange(data);
  });
}
```

#### 2. Heartbeat Monitoring

```typescript
private lastHeartbeat: number = 0;

setupHeartbeatMonitor() {
  this.socket?.on('heartbeat', () => {
    this.lastHeartbeat = Date.now();
    this.socket?.emit('heartbeat_ack');
  });
  
  // Optional: Check if heartbeats are being received
  setInterval(() => {
    const timeSinceHeartbeat = Date.now() - this.lastHeartbeat;
    if (timeSinceHeartbeat > 60000) {
      console.warn('No heartbeat received in 60 seconds - connection may be unstable');
    }
  }, 60000);
}
```

## How It Works

### 1. Connection Flow

```
Client                          Server
  |                               |
  |--- connect(auth: token) ----->|
  |                               |--- Decode token
  |                               |--- Query user from DB
  |                               |--- Set is_online = true
  |<--- user_status (online) -----|--- Broadcast to others
  |                               |--- Start heartbeat timer
```

### 2. Heartbeat Flow

```
Client                          Server
  |                               |
  |<-------- heartbeat -----------|  (every 30s)
  |                               |
  |---- heartbeat_ack ----------->|
  |                               |--- Update is_online = true
  |                               |--- Update last_seen timestamp
```

### 3. Disconnect Flow

```
Client                          Server
  |                               |
  |--- disconnect ---------------->|
  |                               |--- Clear heartbeat timer
  |                               |--- Set is_online = false
  |<--- user_status (offline) ----|--- Broadcast to others
```

## Testing Checklist

Use this checklist to verify the fix works correctly:

### Server Logs
- [ ] See 🔌 emoji when client connects
- [ ] See 🔐 emoji with auth attempt details
- [ ] See 🔍 emoji with decoded userId
- [ ] See ✅ emoji when user authenticated
- [ ] See ✅ emoji when marked as online
- [ ] See ❌ emoji if errors occur

### Database
- [ ] Check `is_online = true` when user connects
- [ ] Check `last_seen` updates every ~30 seconds
- [ ] Check `is_online = false` when user disconnects

### API Endpoint
- [ ] `/hangouts` endpoint returns only online users
- [ ] Users appear in results when `is_online = true`
- [ ] Users disappear from results when disconnected

### Multi-Device Testing
- [ ] Connect two devices with different accounts
- [ ] Device A sees Device B in Hangout/Discover tab
- [ ] Device B sees Device A in Hangout/Discover tab
- [ ] Disconnect Device A → Device B no longer sees Device A
- [ ] Reconnect Device A → Device B sees Device A again

## Troubleshooting

### Users Not Appearing Online

1. **Check Server Logs**
   ```
   Should see:
   🔌 WebSocket client connected: <socket-id>
   🔐 WebSocket auth attempt: { socketId: '...', hasToken: true, tokenLength: ... }
   🔍 Decoded token - userId: <user-id>
   ✅ User authenticated: <username>
   ✅ <username> marked as online
   ```

2. **Check Database**
   ```sql
   SELECT username, is_online, last_seen 
   FROM users 
   WHERE username = 'your-username';
   ```

3. **Check Token Format**
   - Token should be base64 encoded: `userId:timestamp`
   - Example: `Buffer.from('123:1699999999999').toString('base64')`

### Heartbeat Not Working

1. **Check Client Console**
   - Should see heartbeat events every 30 seconds
   - Verify client emits `heartbeat_ack`

2. **Check Server Logs**
   - No errors should appear during heartbeat updates
   - `last_seen` should update in database

### Connection Issues

1. **CORS Configuration**
   - Ensure client URL is in `CORS_ORIGIN` env variable
   - Check server logs for CORS errors

2. **Network**
   - Verify WebSocket can establish connection
   - Check firewall/proxy settings
   - Test with both `websocket` and `polling` transports

## Database Queries for Verification

### Check Online Users
```sql
SELECT username, is_online, last_seen 
FROM users 
WHERE is_online = true;
```

### Check User Status History
```sql
SELECT username, is_online, last_seen, created_at
FROM users 
WHERE username IN ('user1', 'user2')
ORDER BY last_seen DESC;
```

### Check Hangout Query
```sql
-- This is what the /hangouts endpoint uses
SELECT id, username, name, avatar, background_image, 
       country, city, age, bio, interests, is_online,
       latitude, longitude, status, current_activity
FROM users 
WHERE is_online = true
LIMIT 50;
```

## API Testing

### Test Hangout Endpoint

```bash
# Get online users
curl http://localhost:3000/hangouts?limit=10

# With location filtering
curl "http://localhost:3000/hangouts?limit=10&distance_km=50&user_lat=10.762622&user_lng=106.660172"

# Expected response:
[
  {
    "id": "user-id",
    "username": "testuser",
    "name": "Test User",
    "is_online": true,
    "background_image": "https://...",
    "avatar": "https://...",
    ...
  }
]
```

## Performance Considerations

- **Heartbeat Interval**: 30 seconds is a good balance between server load and responsiveness
- **Database Updates**: Heartbeat updates are async and non-blocking
- **Broadcast Events**: Only sent when status actually changes
- **Memory Usage**: `onlineUsers` Map cleared automatically on disconnect

## Security Notes

- Token validation is currently basic (base64 encoded userId:timestamp)
- In production, implement proper JWT token verification
- Validate user permissions before broadcasting sensitive data
- Rate limit heartbeat acknowledgments to prevent abuse

## Next Steps

1. Deploy server with these changes
2. Update client to handle heartbeat events
3. Test with multiple devices
4. Monitor server logs for issues
5. Verify database `is_online` status updates correctly

## Support

If you encounter issues:
1. Check server logs for emoji indicators (🔌 🔐 🔍 ✅ ❌)
2. Verify database `is_online` status
3. Test `/hangouts` endpoint response
4. Ensure client implements `heartbeat_ack`

## Changelog

### 2025-11-14
- Added detailed authentication logging with emojis
- Converted Promise chains to async/await
- Implemented heartbeat mechanism (30s interval)
- Enhanced disconnect handler with async/await
- Added user_status broadcasts for online/offline events
- Improved error handling throughout WebSocket lifecycle
