# Pro Package Testing Guide

This guide explains how to test the Pro package subscription feature in the ConnectSphere app.

## Overview

The Pro package is a premium subscription that provides:
- 512 friends limit (vs 16 for free)
- Premium theme (Yellow vs Blue for free)
- AI features (coming soon)
- Ad-free experience
- Priority event access

**Price**: 50,000 VND per month (test price)

## Database Tables

The payment system uses two main tables:

### 1. user_subscriptions
Stores the current subscription status for each user.

```sql
CREATE TABLE user_subscriptions (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('free', 'pro')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. payment_transactions
Records all payment transactions (for audit trail).

```sql
CREATE TABLE payment_transactions (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'VND',
  plan_type TEXT NOT NULL CHECK (plan_type IN ('pro')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT DEFAULT 'test',
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## API Endpoints

### 1. Get Available Plans
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
      "features": ["16 friends limit", "Basic messaging", "Standard theme (Blue)", ...],
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
      "features": ["512 friends limit", "Premium messaging", "Premium theme (Yellow)", ...],
      "max_friends": 512,
      "theme": "yellow",
      "ai_enabled": true
    }
  ]
}
```

### 2. Get Current Subscription
```http
GET /payments/subscription?username=johndoe
```

**Response:**
```json
{
  "id": 1,
  "username": "johndoe",
  "plan_type": "free",
  "status": "active",
  "start_date": "2025-11-11T00:00:00Z",
  "end_date": null,
  "created_at": "2025-11-11T00:00:00Z",
  "updated_at": "2025-11-11T00:00:00Z"
}
```

**Note:** If no subscription exists, a free subscription will be automatically created.

### 3. Subscribe to Pro Plan (Test Payment)
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
    "start_date": "2025-11-11T00:00:00Z",
    "end_date": "2025-12-11T00:00:00Z",
    "created_at": "2025-11-11T00:00:00Z",
    "updated_at": "2025-11-11T00:00:00Z"
  },
  "transaction": {
    "id": 1,
    "username": "johndoe",
    "amount": 50000,
    "currency": "VND",
    "plan_type": "pro",
    "status": "completed",
    "payment_method": "test",
    "transaction_date": "2025-11-11T00:00:00Z",
    "created_at": "2025-11-11T00:00:00Z"
  },
  "message": "Successfully subscribed to Pro plan!"
}
```

**Side Effects:**
- Updates `user_subscriptions` table
- Creates a record in `payment_transactions` table
- Updates `users` table:
  - `is_premium` = true
  - `max_friends` = 512
  - `theme_preference` = "yellow"

### 4. Cancel Subscription
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
    "start_date": "2025-11-11T00:00:00Z",
    "end_date": "2025-11-11T00:00:00Z",
    "created_at": "2025-11-11T00:00:00Z",
    "updated_at": "2025-11-11T00:00:00Z"
  },
  "message": "Subscription cancelled. Downgraded to Free plan."
}
```

**Side Effects:**
- Updates `user_subscriptions` to free plan with cancelled status
- Updates `users` table:
  - `is_premium` = false
  - `max_friends` = 16
  - `theme_preference` = "blue"

### 5. Get Payment History
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
    "transaction_date": "2025-11-11T00:00:00Z",
    "created_at": "2025-11-11T00:00:00Z"
  }
]
```

## Testing Flow

### Step 1: Check Available Plans
```bash
curl -X GET http://localhost:3000/payments/plans
```

### Step 2: Check Current Subscription (should create free subscription if none exists)
```bash
curl -X GET "http://localhost:3000/payments/subscription?username=testuser"
```

### Step 3: Subscribe to Pro Plan
```bash
curl -X POST http://localhost:3000/payments/subscribe \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "plan_type": "pro",
    "payment_method": "test"
  }'
```

### Step 4: Verify User Profile Updated
```bash
curl -X GET http://localhost:3000/users/username/testuser
```

Check that:
- `is_premium` is `true`
- `max_friends` is `512`
- `theme_preference` is `"yellow"`

### Step 5: Check Payment History
```bash
curl -X GET "http://localhost:3000/payments/history?username=testuser"
```

### Step 6: Cancel Subscription
```bash
curl -X POST http://localhost:3000/payments/cancel \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser"
  }'
```

### Step 7: Verify User Profile Downgraded
```bash
curl -X GET http://localhost:3000/users/username/testuser
```

Check that:
- `is_premium` is `false`
- `max_friends` is `16`
- `theme_preference` is `"blue"`

## Client Integration

The client should:

1. **Display Plans**: Call `GET /payments/plans` to show available plans
2. **Check Status**: Call `GET /payments/subscription?username={user}` to show current plan
3. **Subscribe**: Call `POST /payments/subscribe` when user clicks "Subscribe to Pro"
4. **Show Benefits**: Display the pro benefits (yellow theme, 512 friends limit, etc.)
5. **Cancel**: Provide option to cancel via `POST /payments/cancel`
6. **History**: Show payment history via `GET /payments/history`

## Testing in Postman

1. Import the `Payment-API.postman_collection.json` file
2. Set the `baseUrl` variable to your server URL (e.g., `http://localhost:3000`)
3. Set the `username` variable to your test username
4. Run the requests in order:
   - Get Plans
   - Get Current Subscription
   - Subscribe to Pro
   - Get Updated Subscription
   - Get Payment History
   - Cancel Subscription
   - Verify Downgrade

## Important Notes

1. **Test Payment**: The payment is automatically completed with `status: 'completed'` for testing purposes. In production, you would integrate with a real payment gateway.

2. **Subscription Expiry**: Pro subscriptions expire after 1 month. The server automatically checks expiry when fetching subscription and downgrades to free if expired.

3. **Automatic Free Subscription**: If a user has no subscription record, calling `GET /payments/subscription` will automatically create a free subscription.

4. **Premium Features**: The server updates the user's `is_premium`, `max_friends`, and `theme_preference` fields. The client should check these fields to enable/disable premium features.

5. **Theme**: The app should switch between blue (free) and yellow (pro) themes based on `theme_preference` field.

## Troubleshooting

### Subscription not updating
- Check database tables exist: `user_subscriptions`, `payment_transactions`
- Check users table has columns: `is_premium`, `max_friends`, `theme_preference`
- Check server logs for errors

### User profile not showing premium status
- Verify `users` table was updated after subscription
- Check that client is fetching updated user profile
- Ensure client is reading the correct fields (`is_premium`, `max_friends`, `theme_preference`)

### Payment history not showing
- Verify transaction was created in `payment_transactions` table
- Check username matches exactly (case-sensitive)
- Check server logs for database errors

## Database Queries for Testing

### Check subscription status
```sql
SELECT * FROM user_subscriptions WHERE username = 'testuser';
```

### Check user premium status
```sql
SELECT username, is_premium, max_friends, theme_preference 
FROM users 
WHERE username = 'testuser';
```

### Check payment transactions
```sql
SELECT * FROM payment_transactions WHERE username = 'testuser' ORDER BY created_at DESC;
```

### Manually set user to pro (for testing)
```sql
-- Update subscription
INSERT INTO user_subscriptions (username, plan_type, status, start_date, end_date)
VALUES ('testuser', 'pro', 'active', NOW(), NOW() + INTERVAL '1 month')
ON CONFLICT (username) DO UPDATE
SET plan_type = 'pro', status = 'active', end_date = NOW() + INTERVAL '1 month';

-- Update user
UPDATE users 
SET is_premium = true, max_friends = 512, theme_preference = 'yellow'
WHERE username = 'testuser';
```

### Manually reset to free (for testing)
```sql
-- Update subscription
UPDATE user_subscriptions 
SET plan_type = 'free', status = 'active', end_date = NULL
WHERE username = 'testuser';

-- Update user
UPDATE users 
SET is_premium = false, max_friends = 16, theme_preference = 'blue'
WHERE username = 'testuser';
```

## Summary

The Pro package system is fully functional and ready for testing. It provides:
- ✅ Plan listing
- ✅ Subscription management
- ✅ Test payment processing
- ✅ Automatic user profile updates
- ✅ Payment history tracking
- ✅ Subscription cancellation
- ✅ Automatic expiry handling

Use this guide to test the Pro package feature thoroughly before deploying to production.
