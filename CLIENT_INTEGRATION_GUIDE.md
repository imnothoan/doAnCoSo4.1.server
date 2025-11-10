# Server Updates for Client Integration

## Overview
This document describes the server-side changes made to support the requested features. The client application needs to integrate with these new endpoints and handle the updated data structures.

## Changes Summary

### 1. Inbox Display Fix ✅

**Problem:** Inbox wasn't showing the other participant's name and avatar for DM conversations.

**Solution:** The `GET /messages/conversations?user=username` endpoint now includes an `other_participant` field for DM conversations.

**Response Structure:**
```json
{
  "id": 1,
  "type": "dm",
  "title": null,
  "created_by": "user1",
  "last_message": {
    "id": 123,
    "content": "Hello!",
    "sender_username": "user2",
    "sender": {
      "id": "uuid",
      "username": "user2",
      "name": "User Two",
      "avatar": "https://..."
    }
  },
  "unread_count": 2,
  "other_participant": {
    "id": "uuid",
    "username": "user2",
    "name": "User Two",
    "avatar": "https://..."
  }
}
```

**Client Integration:**
- For DM conversations, use `other_participant.name` and `other_participant.avatar` to display in the inbox
- For group conversations, use the conversation `title` or show member avatars

---

### 2. Double Message Fix ✅

**Problem:** Messages appeared twice when sent - once from client optimistic update and once from WebSocket broadcast.

**Solution:** WebSocket now emits different events for sender vs. other participants.

**WebSocket Events:**
- **`message_sent`** - Sent only to the sender as confirmation (use this to update UI)
- **`new_message`** - Sent to other participants in the room

**Client Integration:**
```javascript
// When sending a message
socket.emit('send_message', {
  conversationId,
  senderUsername,
  content,
  replyToMessageId
});

// Listen for confirmation (sender only)
socket.on('message_sent', (message) => {
  // Replace optimistic message with real one from server
  // message has id, created_at, etc.
});

// Listen for new messages from others
socket.on('new_message', (message) => {
  // Add message to conversation
});
```

**Recommended Flow:**
1. User types message and clicks send
2. Add message to UI optimistically (with temporary ID)
3. Emit `send_message` to server
4. Wait for `message_sent` event
5. Replace optimistic message with real message from server
6. Don't listen to your own `new_message` events

---

### 3. Payment & Pro Features System ✅

**New Features:**
- Test payment system (no real money)
- Pro plan subscription (monthly, no auto-renewal)
- 512 friend limit for Pro (vs 16 for Free)
- Yellow theme for Pro users (vs Blue for Free)
- AI post writing (placeholder - to be implemented)

**New Endpoints:**

#### Get Available Plans
```http
GET /payments/plans
```

Returns:
```json
{
  "plans": [
    {
      "id": "free",
      "name": "Free Plan",
      "price": 0,
      "max_friends": 16,
      "theme": "blue",
      "ai_enabled": false,
      "features": [...]
    },
    {
      "id": "pro",
      "name": "Pro Plan",
      "price": 50000,
      "currency": "VND",
      "max_friends": 512,
      "theme": "yellow",
      "ai_enabled": true,
      "features": [...]
    }
  ]
}
```

#### Get User's Subscription
```http
GET /payments/subscription?username=johndoe
```

Returns:
```json
{
  "username": "johndoe",
  "plan_type": "pro",
  "status": "active",
  "start_date": "2025-01-01T00:00:00Z",
  "end_date": "2025-02-01T00:00:00Z"
}
```

#### Subscribe to Pro
```http
POST /payments/subscribe
Content-Type: application/json

{
  "username": "johndoe",
  "plan_type": "pro",
  "payment_method": "test"
}
```

**What happens on subscription:**
1. Creates payment transaction record (test payment - auto-completed)
2. Updates/creates subscription record (valid for 1 month)
3. Sets user's `is_premium = true`
4. Sets user's `max_friends = 512`
5. Sets user's `theme_preference = 'yellow'`

#### Cancel Subscription
```http
POST /payments/cancel

{
  "username": "johndoe"
}
```

**What happens on cancellation:**
1. Updates subscription to "cancelled"
2. Sets user's `is_premium = false`
3. Sets user's `max_friends = 16`
4. Sets user's `theme_preference = 'blue'`

#### Payment History
```http
GET /payments/history?username=johndoe
```

Returns array of payment transactions.

**Client Integration for Payment Flow:**

1. **Payment & Pro Features Button:**
   - Create a new screen/page for Pro features
   - Show benefits (512 friends, yellow theme, AI features coming soon)
   - Display pricing: 50,000 VND/month

2. **Payment Screen:**
   ```javascript
   // Fetch plans
   const plans = await api.get('/payments/plans');
   
   // Show Pro plan features and price
   // When user clicks "Subscribe"
   const response = await api.post('/payments/subscribe', {
     username: currentUser.username,
     plan_type: 'pro',
     payment_method: 'test'
   });
   
   // Show success message
   // Reload user profile to get updated is_premium status
   ```

3. **Theme Switching:**
   ```javascript
   // In your theme provider
   const user = await api.get(`/users/username/${username}`);
   const theme = user.theme_preference === 'yellow' ? yellowTheme : blueTheme;
   ```

4. **Friend Limit Check:**
   ```javascript
   const user = await api.get(`/users/username/${username}`);
   const currentFollowing = user.following; // count
   const maxFriends = user.max_friends; // 16 or 512
   
   if (currentFollowing >= maxFriends) {
     // Show "Upgrade to Pro" message
     // Disable follow button
   }
   ```

5. **AI Features (Coming Soon):**
   - Show AI button in post creation
   - Check `user.is_premium`
   - If not premium, show upgrade prompt
   - If premium, enable AI features (when implemented)

---

### 4. Account Summary (Already Working) ✅

The following endpoints already exist and work correctly:

#### Get Followers
```http
GET /users/:username/followers?viewer=currentUser
```

Returns array of follower profiles:
```json
[
  {
    "id": "uuid",
    "username": "follower1",
    "name": "Follower One",
    "avatar": "https://...",
    "bio": "...",
    "is_followed_by_viewer": true
  }
]
```

#### Get Following
```http
GET /users/:username/following?viewer=currentUser
```

Returns array of following profiles.

#### Get Profile with Counts
```http
GET /users/username/:username
```

Returns:
```json
{
  "id": "uuid",
  "username": "johndoe",
  "name": "John Doe",
  "avatar": "https://...",
  "followers": 25,
  "following": 18,
  "posts": 42,
  "is_premium": true,
  "max_friends": 512,
  "theme_preference": "yellow",
  ...
}
```

**Client Integration:**
In the Account tab summary section:
```javascript
// Display clickable counts
<TouchableOpacity onPress={() => navigate('Followers', { username })}>
  <Text>{user.followers} Followers</Text>
</TouchableOpacity>

<TouchableOpacity onPress={() => navigate('Following', { username })}>
  <Text>{user.following} Following</Text>
</TouchableOpacity>

// On Followers screen
const followers = await api.get(`/users/${username}/followers?viewer=${currentUser.username}`);
// Display list with follow/unfollow buttons

// On Following screen
const following = await api.get(`/users/${username}/following?viewer=${currentUser.username}`);
// Display list
```

---

## Database Schema Changes

The following tables were added/modified:

### users table (new columns)
- `theme_preference` - TEXT ('blue' or 'yellow')

### user_subscriptions table (new)
- `id` - BIGSERIAL PRIMARY KEY
- `username` - TEXT (FK to users)
- `plan_type` - TEXT ('free' or 'pro')
- `status` - TEXT ('active', 'expired', 'cancelled')
- `start_date` - TIMESTAMP
- `end_date` - TIMESTAMP (NULL for free)
- `created_at` - TIMESTAMP
- `updated_at` - TIMESTAMP

### payment_transactions table (new)
- `id` - BIGSERIAL PRIMARY KEY
- `username` - TEXT (FK to users)
- `amount` - DECIMAL(10,2)
- `currency` - TEXT
- `plan_type` - TEXT ('pro')
- `status` - TEXT ('pending', 'completed', 'failed', 'refunded')
- `payment_method` - TEXT
- `transaction_date` - TIMESTAMP
- `created_at` - TIMESTAMP

---

## Testing Checklist

### Inbox Display
- [ ] Create DM conversation
- [ ] Verify other participant's name shows in inbox
- [ ] Verify other participant's avatar shows in inbox
- [ ] Verify unread count displays correctly

### Messaging
- [ ] Send message via WebSocket
- [ ] Verify message appears once (not twice)
- [ ] Verify message persists after refresh
- [ ] Verify read receipts work

### Payment System
- [ ] View payment plans page
- [ ] Subscribe to Pro plan
- [ ] Verify theme changes to yellow
- [ ] Verify max friends increases to 512
- [ ] Try to follow >16 users as free user (should be blocked)
- [ ] Try to follow >16 users as pro user (should work up to 512)
- [ ] Cancel subscription
- [ ] Verify downgrade to free plan
- [ ] View payment history

### Account Summary
- [ ] View followers count - click to see list
- [ ] View following count - click to see list
- [ ] Verify counts are accurate
- [ ] Verify follow/unfollow buttons work in lists

---

## Notes for Client Development

1. **Theme Implementation:**
   - Create two theme configurations (blue and yellow)
   - Load user's `theme_preference` from profile
   - Apply theme globally in app

2. **Friend Limit Enforcement:**
   - Before allowing follow action, check:
     - Current following count
     - User's max_friends limit
   - Show upgrade prompt if limit reached and user is free

3. **Payment Flow:**
   - This is TEST PAYMENT ONLY
   - No real money is involved
   - Subscriptions last 1 month
   - No auto-renewal (user must manually renew)

4. **WebSocket Best Practices:**
   - Connect to WebSocket on app start
   - Join conversation rooms when opening chat
   - Leave rooms when closing chat
   - Handle reconnection logic
   - Use `message_sent` for sender confirmation
   - Use `new_message` for receiving from others

5. **Subscription Expiry:**
   - Server automatically checks expiry on subscription fetch
   - Client should check subscription status periodically
   - Show renewal prompt when nearing expiry

---

## API Base URL

Development: `http://localhost:3000`
Production: (Set in client environment variables)

---

## Support

For questions or issues with these server changes, please open an issue in the server repository.
