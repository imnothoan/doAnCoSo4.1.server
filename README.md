# ConnectSphere Server

Backend server for ConnectSphere (UniVini-like) app built with Express.js and Supabase.

## ✨ Latest Updates

### Stripe Payment Integration 💳
- 💰 **Real Payment Processing**: Integrated Stripe for secure payment handling
- 🔒 **Server-Side Verification**: All payments verified server-side for security
- 🧪 **Test Mode Support**: Both Stripe test mode and quick test mode available
- 🚫 **Fraud Prevention**: Payment intent uniqueness prevents duplicate payments
- 📊 **Transaction Tracking**: All payments logged with Stripe PaymentIntent IDs

**See detailed documentation:**
- 📖 [Stripe Integration Guide](STRIPE_INTEGRATION.md)
- 🧪 [Payment Test Guide](PRO_PACKAGE_TEST_GUIDE.md)

### Background Image Feature (Tinder-Style Hangout)
- 🖼️ **Background Images**: Users can upload background images separate from avatars
- 👥 **Online Users Discovery**: Hangout endpoint now shows only online users
- 📍 **Distance-Based Matching**: Filter users by proximity
- 💫 **Tinder-Style Cards**: Perfect for swipe-based user discovery

**See detailed documentation:**
- 📖 [English Setup Guide](BACKGROUND_IMAGE_SETUP.md)
- 📖 [Vietnamese Guide (Tiếng Việt)](HUONG_DAN_TRIEN_KHAI.md)
- 📖 [Implementation Summary](IMPLEMENTATION_SUMMARY.md)

## Features

- **User Management**: Complete profile system with languages, countries, interests, and background images
- **Payment System**: Stripe integration for Pro subscriptions with test and live modes
- **Events System**: Create, manage, and participate in events
- **Hangouts**: Connect with nearby online users based on activities and interests (Tinder-style)
- **Communities**: Discussion groups with posts, likes, and comments
- **Messaging**: Real-time conversations with media support
- **Notifications**: Push notifications for various activities
- **Quick Messages**: Custom shortcuts for frequently used messages

## Tech Stack

- **Node.js** (>= 18.0.0)
- **Express.js**: Web framework
- **Supabase**: PostgreSQL database and authentication
- **Stripe**: Payment processing for Pro subscriptions
- **Multer**: File upload handling
- **Morgan**: HTTP request logger
- **CORS**: Cross-origin resource sharing

## Setup

1. **Clone the repository**
```bash
git clone https://github.com/imnothoan/doAnCoSo4.1.server.git
cd doAnCoSo4.1.server
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure environment**
```bash
cp .env.example .env
```

Edit `.env` with your Supabase credentials and Stripe key:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
CORS_ORIGIN=http://localhost:3000,http://localhost:19006
POSTS_BUCKET=posts
AVATARS_BUCKET=avatars
MESSAGES_BUCKET=messages

# Stripe Payment (get test keys from https://dashboard.stripe.com/test/apikeys)
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
```

4. **Set up database**

Run the schema in `db/schema.sql` in your Supabase SQL Editor to create all necessary tables, indexes, and functions.

5. **Run the server**
```bash
# Development with hot reload
npm run dev

# Production
npm start
```

The server will start on port 3000 (or the PORT specified in .env).

## API Endpoints

### Users (`/users`)
- `POST /users/create-profile` - Create or update user profile
- `GET /users/id/:id` - Get user by ID
- `GET /users/username/:username` - Get user by username
- `PUT /users/:id` - Update user profile
- `GET /users/search?q=query` - Search users
- `POST /users/:username/follow` - Follow a user
- `DELETE /users/:username/follow` - Unfollow a user
- `GET /users/:username/followers` - Get user followers
- `GET /users/:username/following` - Get users following
- `GET /users/:username/posts` - Get user posts
- `POST /users/upload-avatar` - Upload avatar
- `POST /users/:userId/avatar` - Upload avatar (client-preferred)
- **`POST /users/:userId/background-image`** - Upload background image (NEW)
- `GET /users/:username/languages` - Get user languages
- `POST /users/:username/languages` - Add user language
- `GET /users/:username/countries` - Get user countries
- `POST /users/:username/countries` - Add user country
- `GET /users/:username/profile-completion` - Get profile completion status

### Events (`/events`)
- `POST /events` - Create event
- `GET /events` - List events (with filters: distance, status)
- `GET /events/:id` - Get event details
- `PUT /events/:id` - Update event
- `DELETE /events/:id` - Delete event
- `POST /events/:id/participate` - Join/update participation
- `DELETE /events/:id/participate` - Leave event
- `GET /events/:id/participants` - Get participants
- `POST /events/:id/invite` - Invite users to event
- `POST /events/:id/comments` - Add comment
- `GET /events/:id/comments` - Get comments
- `GET /events/user/:username/created` - Get user's created events
- `GET /events/user/:username/participating` - Get user's participating events

### Hangouts (`/hangouts`)
- **`GET /hangouts`** - Get online users for Tinder-style hangout (UPDATED - returns users instead of hangout objects)
- `PUT /hangouts/status` - Update hangout availability
- `GET /hangouts/status/:username` - Get hangout status
- `POST /hangouts` - Create hangout
- `GET /hangouts/:id` - Get hangout details
- `PUT /hangouts/:id` - Update hangout
- `DELETE /hangouts/:id` - Delete hangout
- `POST /hangouts/:id/join` - Join hangout
- `DELETE /hangouts/:id/join` - Leave hangout
- `GET /hangouts/:id/participants` - Get participants
- `POST /hangouts/connections` - Create connection
- `GET /hangouts/connections/:username` - Get user connections
- `GET /hangouts/user/:username/created` - Get created hangouts
- `GET /hangouts/user/:username/joined` - Get joined hangouts

### Communities (`/communities`)
- `POST /communities` - Create community
- `GET /communities` - List/search communities
- `GET /communities/suggested` - Get suggested communities
- `GET /communities/:id` - Get community details
- `PUT /communities/:id` - Update community
- `DELETE /communities/:id` - Delete community
- `POST /communities/:id/join` - Join community
- `DELETE /communities/:id/join` - Leave community
- `GET /communities/:id/members` - Get members
- `POST /communities/:id/posts` - Create post
- `GET /communities/:id/posts` - Get posts
- `DELETE /communities/:id/posts/:postId` - Delete post
- `POST /communities/:id/posts/:postId/like` - Like post
- `DELETE /communities/:id/posts/:postId/like` - Unlike post
- `POST /communities/:id/posts/:postId/comments` - Add comment
- `GET /communities/:id/posts/:postId/comments` - Get comments

### Posts (`/posts`)
- `POST /posts` - Create post with media
- `GET /posts` - List posts
- `GET /posts/:id` - Get post
- `PUT /posts/:id` - Update post
- `DELETE /posts/:id` - Delete post
- `POST /posts/:id/like` - Like post
- `DELETE /posts/:id/like` - Unlike post
- `POST /posts/:id/comments` - Add comment
- `GET /posts/:id/comments` - Get comments

### Messages (`/messages`)
- `POST /messages/conversations` - Create conversation
- `GET /messages/conversations` - List conversations
- `GET /messages/conversations/:id` - Get conversation
- `POST /messages/conversations/:id/members` - Add members
- `DELETE /messages/conversations/:id/members/:username` - Remove member
- `GET /messages/conversations/:id/messages` - Get messages
- `POST /messages/conversations/:id/messages` - Send text message
- `POST /messages/conversations/:id/messages/media` - Send media message
- `DELETE /messages/conversations/:id/messages/:messageId` - Delete message
- `POST /messages/conversations/:id/read` - Mark as read
- `POST /messages/conversations/:id/reactions` - Add reaction
- `DELETE /messages/conversations/:id/reactions` - Remove reaction

### Notifications (`/notifications`)
- `GET /notifications` - Get notifications
- `GET /notifications/unread-count` - Get unread count
- `PUT /notifications/mark-read` - Mark as read
- `DELETE /notifications/:id` - Delete notification
- `POST /notifications` - Create notification (internal)

### Quick Messages (`/quick-messages`)
- `GET /quick-messages` - Get user's quick messages
- `POST /quick-messages` - Create quick message
- `PUT /quick-messages/:id` - Update quick message
- `DELETE /quick-messages/:id` - Delete quick message
- `GET /quick-messages/expand` - Expand shortcut

### Payments (`/payments`) 💳
- `GET /payments/plans` - Get available payment plans
- `POST /payments/create-payment-intent` - Create Stripe payment intent (NEW)
- `POST /payments/subscribe` - Subscribe to Pro plan (supports Stripe & test mode)
- `POST /payments/cancel` - Cancel subscription
- `GET /payments/subscription` - Get user's subscription status
- `GET /payments/history` - Get payment transaction history

**Payment Integration:**
- See [Stripe Integration Guide](STRIPE_INTEGRATION.md) for setup and usage
- Supports both Stripe payments and test mode for development

## Database Schema

See `db/schema.sql` for the complete database schema including:
- Users with extended profiles
- Events and event participants
- Hangouts and connections
- Communities and community posts
- Messages and conversations
- Notifications
- Quick messages
- User languages and countries
- **Payment transactions and subscriptions** (NEW)

### Recent Schema Updates
- Added `payment_intent_id` column to `payment_transactions` table
- See `db/migrations/add_stripe_payment_intent_id.sql` for migration

## Client Integration

This server is designed to work with the React Native (Expo) client app at:
https://github.com/imnothoan/doAnCoSo4.1

The client uses these API endpoints to provide a UniVini-like experience with:
- Event discovery and participation
- Hangout matching based on location and interests
- Community discussions
- Real-time messaging
- User profiles and connections

## Development

- `npm run dev` - Start with nodemon for auto-reload
- `npm start` - Start in production mode

## License

Private repository - all rights reserved
