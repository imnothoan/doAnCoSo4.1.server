# Database Migration Guide

## Overview
This guide helps you apply the new database schema changes for the payment and subscription features.

## Prerequisites
- Access to Supabase SQL Editor
- Backup your database before running migrations (recommended)

## Migration Steps

### Step 1: Add Theme Preference Column
This adds the theme preference column to the users table.

```sql
-- Add theme preference column (blue for free, yellow for pro)
ALTER TABLE users ADD COLUMN IF NOT EXISTS theme_preference TEXT DEFAULT 'blue' 
  CHECK (theme_preference IN ('blue', 'yellow'));
```

### Step 2: Create User Subscriptions Table
This table tracks user subscription status.

```sql
-- Create user subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('free', 'pro')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE, -- NULL for free plan, set for pro plan
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(username)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_username ON user_subscriptions(username);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON user_subscriptions;
CREATE TRIGGER update_user_subscriptions_updated_at 
  BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();
```

### Step 3: Create Payment Transactions Table
This table stores test payment transaction history.

```sql
-- Create payment transactions table
CREATE TABLE IF NOT EXISTS payment_transactions (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'VND',
  plan_type TEXT NOT NULL CHECK (plan_type IN ('pro')),
  status TEXT NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT DEFAULT 'test', -- test payment
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_payment_transactions_username ON payment_transactions(username);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
```

### Step 4: Initialize Existing Users (Optional)
If you have existing users and want to initialize their subscriptions as free:

```sql
-- Create free subscriptions for all existing users without a subscription
INSERT INTO user_subscriptions (username, plan_type, status, start_date, end_date)
SELECT 
  username,
  'free' as plan_type,
  'active' as status,
  NOW() as start_date,
  NULL as end_date
FROM users
WHERE username NOT IN (SELECT username FROM user_subscriptions)
ON CONFLICT (username) DO NOTHING;
```

### Step 5: Verify Migration
Check that everything is created correctly:

```sql
-- Check theme_preference column exists
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'theme_preference';

-- Check user_subscriptions table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'user_subscriptions';

-- Check payment_transactions table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'payment_transactions';

-- Check indexes
SELECT indexname, tablename 
FROM pg_indexes 
WHERE tablename IN ('user_subscriptions', 'payment_transactions');
```

## Rollback (If Needed)

If you need to rollback the migration:

```sql
-- WARNING: This will delete all subscription and payment data
DROP TABLE IF EXISTS payment_transactions CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
ALTER TABLE users DROP COLUMN IF EXISTS theme_preference;
```

## Post-Migration Testing

After running the migration, test the following:

1. **Get Plans**
   ```bash
   curl http://localhost:3000/payments/plans
   ```

2. **Get User Subscription** (should create free subscription if none exists)
   ```bash
   curl http://localhost:3000/payments/subscription?username=testuser
   ```

3. **Subscribe to Pro**
   ```bash
   curl -X POST http://localhost:3000/payments/subscribe \
     -H "Content-Type: application/json" \
     -d '{"username":"testuser","plan_type":"pro","payment_method":"test"}'
   ```

4. **Check User Profile** (should show is_premium=true, max_friends=512, theme_preference='yellow')
   ```bash
   curl http://localhost:3000/users/username/testuser
   ```

## Notes

- The migration is idempotent - you can run it multiple times safely
- All `IF NOT EXISTS` clauses prevent errors on re-runs
- Test payments are auto-completed with status 'completed'
- Subscriptions expire after 1 month but are not automatically renewed
- Server checks expiry on subscription fetch and downgrades if needed

## Troubleshooting

**Issue: Column already exists**
- Safe to ignore if using `IF NOT EXISTS`
- Migration is idempotent

**Issue: Table already exists**
- Safe to ignore if using `IF NOT EXISTS`
- Check if indexes also exist

**Issue: Foreign key constraint fails**
- Ensure users table exists
- Ensure referenced usernames exist in users table

**Issue: Function update_updated_at_column does not exist**
- This function should already exist in your schema
- Check db/schema.sql for the function definition
- It's defined earlier in the schema file

## Support

If you encounter any issues:
1. Check Supabase logs for detailed error messages
2. Verify your database version is compatible (PostgreSQL 12+)
3. Ensure you have proper permissions to create tables
4. Open an issue in the repository with error details
