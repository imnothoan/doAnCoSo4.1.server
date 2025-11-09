# Database Setup Guide

This guide will help you set up the ConnectSphere database schema in Supabase.

## Prerequisites

1. A Supabase account (https://supabase.com)
2. A Supabase project created

## Setup Steps

### 1. Access SQL Editor

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**

### 2. Run the Schema

1. Open the file `db/schema.sql` in this repository
2. Copy the entire contents
3. Paste into the Supabase SQL Editor
4. Click **Run** (or press `Ctrl+Enter` / `Cmd+Enter`)

The script will create:
- All necessary tables
- Indexes for performance
- Views for aggregated data
- Functions for common operations
- Triggers for automatic updates

### 3. Create Storage Buckets

You need to create three storage buckets for file uploads:

1. Go to **Storage** in the Supabase dashboard
2. Create the following buckets:

   **Bucket: `avatars`**
   - Public: ✅ Yes
   - File size limit: 2 MB
   - Allowed MIME types: image/jpeg, image/png, image/gif, image/webp

   **Bucket: `posts`**
   - Public: ✅ Yes
   - File size limit: 10 MB
   - Allowed MIME types: image/jpeg, image/png, image/gif, image/webp, video/mp4

   **Bucket: `messages`**
   - Public: ✅ Yes
   - File size limit: 10 MB
   - Allowed MIME types: image/jpeg, image/png, image/gif, image/webp, video/mp4, audio/mpeg

### 4. Configure Row Level Security (Optional but Recommended)

For production, you should enable Row Level Security (RLS) on sensitive tables:

```sql
-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow users to read all profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON users FOR SELECT
  USING (true);

-- Allow users to update only their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid()::text = id);

-- Repeat for other tables as needed
```

### 5. Get Your Credentials

1. Go to **Settings** > **API** in your Supabase dashboard
2. Copy the following values:
   - Project URL (`SUPABASE_URL`)
   - `anon` public key (`SUPABASE_ANON_KEY`)
   - `service_role` secret key (`SUPABASE_SERVICE_ROLE_KEY`)

3. Create a `.env` file in the server root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
CORS_ORIGIN=http://localhost:19006,http://localhost:3000
POSTS_BUCKET=posts
AVATARS_BUCKET=avatars
MESSAGES_BUCKET=messages
NODE_ENV=development
```

### 6. Test the Connection

Run the test script to verify your connection:

```bash
node testSupabase.js
```

You should see:
```
✅ Supabase client initialized successfully
Checking connection Supabase...
Success: []
```

### 7. Verify Tables

In the Supabase SQL Editor, run:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

You should see all the tables listed:
- users
- user_languages
- user_countries
- user_follows
- events
- event_participants
- event_invitations
- event_comments
- hangouts
- hangout_participants
- hangout_connections
- user_hangout_status
- communities
- community_members
- community_posts
- community_post_likes
- community_post_comments
- posts
- post_media
- post_likes
- comments
- conversations
- conversation_members
- messages
- message_media
- message_reads
- message_reactions
- notifications
- quick_messages

## Troubleshooting

### Error: "relation already exists"

If you see this error, some tables already exist. You can either:

1. Drop existing tables first (⚠️ this will delete all data):
   ```sql
   DROP SCHEMA public CASCADE;
   CREATE SCHEMA public;
   ```

2. Or manually run only the parts of the schema that don't exist yet.

### Error: "permission denied"

Make sure you're using the `service_role` key, not the `anon` key, when running the schema.

### Error: "function does not exist"

Make sure you've run the entire schema.sql file, including the function definitions at the end.

### Storage bucket errors

Make sure the bucket names in your `.env` file match exactly with the bucket names created in Supabase Storage.

## Optional: Seed Data

For testing, you can add sample data:

```sql
-- Insert test user
INSERT INTO users (id, email, username, name, gender, bio, country, city, status)
VALUES 
  ('test-uuid-1', 'john@example.com', 'johndoe', 'John Doe', 'Male', 
   'Love traveling and meeting new people', 'Vietnam', 'Ho Chi Minh', 'Open to Chat');

-- Insert test event
INSERT INTO events (hosted_by, name, description, address, date_start, date_end, 
                    latitude, longitude, entrance_fee)
VALUES 
  ('johndoe', 'Garden by Bottega 5', 'Weekly Friday night event', 
   '123 Main St, District 1', '2025-11-07 19:30:00', '2025-11-07 23:30:00',
   10.7769, 106.7009, 'Free');

-- Add more test data as needed
```

## Next Steps

Once the database is set up:

1. Start the server: `npm run dev`
2. Test the API endpoints using Postman or curl
3. Connect the React Native client app
4. Deploy the server to production (Railway, Render, etc.)

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostGIS for location queries](https://postgis.net/) (if you need advanced geo features)
