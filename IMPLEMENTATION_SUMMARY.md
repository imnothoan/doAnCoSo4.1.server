# Implementation Summary: Background Image Feature

## Overview
This implementation adds background image support to the ConnectSphere server to enable a Tinder-like hangout experience. Users can now upload background images separate from their avatars, and the hangout endpoint returns only online users with their background images for swiping functionality.

## Changes Made

### 1. Database Schema Updates

#### File: `db/schema.sql`
- Added `background_image` column to users table
- Created index on `background_image` for improved query performance

#### File: `db/migrations/add_background_image.sql` (NEW)
- Standalone migration file for adding the background_image column
- Can be executed independently in Supabase SQL Editor

**SQL to Run:**
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS background_image TEXT;
CREATE INDEX IF NOT EXISTS idx_users_background_image ON users(background_image) WHERE background_image IS NOT NULL;
```

### 2. Server Code Updates

#### File: `index.js`
**Changes:**
- Added import for supabase client
- Created `initializeStorageBucket()` function to automatically create the `background-images` bucket on server startup
- Function handles the "already exists" case gracefully

**Key Code:**
```javascript
async function initializeStorageBucket() {
  const { data, error } = await supabase.storage.createBucket("background-images", {
    public: true,
    fileSizeLimit: 10485760, // 10MB
    allowedMimeTypes: ["image/jpeg", "image/png", "image/jpg"],
  });
  // Error handling...
}
```

#### File: `routes/user.routes.js`
**Changes:**

1. **New Endpoint - Upload Background Image:**
   - Route: `POST /users/:userId/background-image`
   - Accepts: `multipart/form-data` with `background_image` file
   - Uploads to `background-images` bucket in Supabase Storage
   - Returns public URL of uploaded image
   - Updates user record with the URL

2. **Updated Endpoint - Update User Profile:**
   - Route: `PUT /users/:id`
   - Now accepts `background_image` field in request body
   - Allows updating background_image URL directly

**Example Request:**
```bash
curl -X POST http://localhost:3000/users/[USER_ID]/background-image \
  -F "background_image=@/path/to/image.jpg"
```

**Example Response:**
```json
{
  "backgroundImageUrl": "https://[project].supabase.co/storage/v1/object/public/background-images/[userId]-[timestamp].jpg"
}
```

#### File: `routes/hangout.routes.js`
**Changes:**
- **Completely rewrote `GET /hangouts` endpoint**
- Previously returned hangout objects
- Now returns **online users only** (`is_online = true`)
- Includes all necessary fields for Tinder-like UI:
  - `id`, `username`, `name`, `avatar`
  - **`background_image`** (new)
  - `age`, `bio`, `interests`, `country`, `city`
  - `latitude`, `longitude` for distance calculation
  - `status`, `current_activity`

**Key Features:**
- Filters for online users only
- Calculates distance from user's location if provided
- Supports distance filtering (e.g., show users within 10km)
- Sorts by distance when location is provided
- Returns up to 100 users (configurable via `limit` parameter)

**Example Request:**
```bash
curl "http://localhost:3000/hangouts?limit=50&distance_km=10&user_lat=10.762622&user_lng=106.660172"
```

**Example Response:**
```json
[
  {
    "id": "uuid",
    "username": "alice",
    "name": "Alice",
    "avatar": "https://...",
    "background_image": "https://...",
    "age": 25,
    "bio": "Love traveling!",
    "interests": ["Travel", "Language Exchange"],
    "is_online": true,
    "country": "Vietnam",
    "city": "Ho Chi Minh",
    "latitude": 10.762622,
    "longitude": 106.660172,
    "distance": 2.5
  }
]
```

### 3. Documentation

#### File: `BACKGROUND_IMAGE_SETUP.md` (NEW)
Comprehensive setup guide including:
- Database migration instructions
- Supabase Storage bucket creation (manual and automatic)
- API endpoint documentation
- Client integration examples
- Security considerations
- Troubleshooting guide

## How to Use

### For Developers (Server Setup)

1. **Update Database:**
   ```sql
   -- Run in Supabase SQL Editor
   ALTER TABLE users ADD COLUMN IF NOT EXISTS background_image TEXT;
   CREATE INDEX IF NOT EXISTS idx_users_background_image ON users(background_image) WHERE background_image IS NOT NULL;
   ```

2. **Create Storage Bucket (Optional):**
   - The server will automatically create the bucket on startup
   - Or manually create via Supabase Dashboard: Storage → Create bucket → `background-images` (public, 10MB limit)

3. **Start Server:**
   ```bash
   npm install
   npm start
   ```
   The server will automatically attempt to create the `background-images` bucket.

### For Client Developers

1. **Upload Background Image:**
   ```javascript
   const formData = new FormData();
   formData.append('background_image', {
     uri: imageUri,
     type: 'image/jpeg',
     name: 'background.jpg',
   });

   const response = await fetch(`${API_URL}/users/${userId}/background-image`, {
     method: 'POST',
     body: formData,
   });

   const { backgroundImageUrl } = await response.json();
   ```

2. **Fetch Online Users for Hangout:**
   ```javascript
   const response = await fetch(
     `${API_URL}/hangouts?limit=50&distance_km=10&user_lat=${lat}&user_lng=${lng}`
   );
   const users = await response.json();
   ```

3. **Display Tinder-like Card:**
   ```jsx
   <ImageBackground 
     source={{ uri: user.background_image || user.avatar }} 
     style={styles.backgroundImage}
   >
     <LinearGradient
       colors={['transparent', 'rgba(0,0,0,0.8)']}
       style={styles.gradient}
     >
       <View style={styles.infoContainer}>
         <Text style={styles.name}>{user.name}, {user.age}</Text>
         <Text style={styles.bio}>{user.bio}</Text>
         <View style={styles.interests}>
           {user.interests?.map(interest => (
             <Chip key={interest}>{interest}</Chip>
           ))}
         </View>
       </View>
     </LinearGradient>
   </ImageBackground>
   ```

## API Endpoints Summary

### New Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/users/:userId/background-image` | Upload background image for user |

### Modified Endpoints
| Method | Endpoint | Changes |
|--------|----------|---------|
| PUT | `/users/:id` | Now accepts `background_image` field |
| GET | `/users/id/:id` | Returns `background_image` field |
| GET | `/users/username/:username` | Returns `background_image` field |
| GET | `/users/:id` (UUID) | Returns `background_image` field |
| GET | `/hangouts` | **BREAKING CHANGE**: Now returns online users instead of hangout objects |

## Breaking Changes

⚠️ **Important:** The `GET /hangouts` endpoint behavior has changed:

**Before:**
- Returned hangout objects (events/meetups)
- Response: `[{ id, title, description, creator_username, ... }]`

**After:**
- Returns online users for Tinder-like swiping
- Response: `[{ id, username, name, background_image, is_online, ... }]`

**Migration Path:**
If the client needs the old hangout functionality (events/meetups), consider:
1. Creating a new endpoint `/hangouts/events` for the old behavior
2. Or updating client to use the new user-based hangout system

## Security Analysis

✅ **CodeQL Scan Results:** No vulnerabilities found

**Security Considerations:**
1. **File Upload Security:**
   - File size limited to 10MB
   - Only JPEG, PNG, JPG formats allowed
   - Files stored in public bucket (URLs are publicly accessible)

2. **Authentication:**
   - Endpoint requires valid userId
   - User must exist in database

3. **Recommendations:**
   - Consider adding authentication middleware to verify the user uploading is the same as userId
   - Implement rate limiting for upload endpoint to prevent abuse
   - Consider adding virus scanning for uploaded images
   - Implement automatic cleanup of old background images when new ones are uploaded

## Testing

### Manual Testing

1. **Test Background Image Upload:**
   ```bash
   # Replace USER_ID with actual user ID
   curl -X POST http://localhost:3000/users/[USER_ID]/background-image \
     -F "background_image=@/path/to/test-image.jpg"
   ```

2. **Test Get Online Users:**
   ```bash
   curl "http://localhost:3000/hangouts?limit=10"
   ```

3. **Test Update User Profile:**
   ```bash
   curl -X PUT http://localhost:3000/users/[USER_ID] \
     -H "Content-Type: application/json" \
     -d '{"background_image": "https://example.com/image.jpg"}'
   ```

### Integration Testing

The implementation has been tested for:
- ✅ Syntax validation (all files have valid JavaScript syntax)
- ✅ Server startup (successfully starts with bucket initialization)
- ✅ Security vulnerabilities (CodeQL scan passed with 0 alerts)

## Files Changed

1. ✅ `db/schema.sql` - Added background_image column and index
2. ✅ `db/migrations/add_background_image.sql` - New migration file
3. ✅ `index.js` - Added bucket initialization
4. ✅ `routes/user.routes.js` - Added upload endpoint and updated PUT
5. ✅ `routes/hangout.routes.js` - Rewrote GET /hangouts to return online users
6. ✅ `BACKGROUND_IMAGE_SETUP.md` - New setup documentation
7. ✅ `IMPLEMENTATION_SUMMARY.md` - This file

## Next Steps

### For the User (Repository Owner)

1. **Run Database Migration:**
   - Go to Supabase Dashboard → SQL Editor
   - Run the contents of `db/migrations/add_background_image.sql`
   - Or run: `ALTER TABLE users ADD COLUMN IF NOT EXISTS background_image TEXT;`

2. **Verify Bucket Creation:**
   - Start your server: `npm start`
   - Check logs for "Background images bucket" message
   - Or manually create via Supabase Dashboard

3. **Update Client Application:**
   - Clone/update client repo: https://github.com/imnothoan/doAnCoSo4.1
   - Implement background image upload UI
   - Update hangout screen to use new endpoint format
   - Add Tinder-like swipe cards

4. **Deploy Changes:**
   - Push to production
   - Run database migration on production Supabase instance
   - Verify bucket exists in production

### For Future Enhancements

1. **Recommended Additions:**
   - Authentication middleware for upload endpoints
   - Rate limiting for uploads
   - Automatic old image cleanup
   - Image optimization/resizing on upload
   - Virus scanning for uploaded files

2. **Client Features:**
   - Implement swipe left/right gestures
   - Add matching/liking system
   - Store swipe history to avoid showing same users
   - Add filters (age range, interests, distance)

## Support

If you encounter any issues:
1. Check `BACKGROUND_IMAGE_SETUP.md` for detailed setup instructions
2. Verify database migration was run successfully
3. Ensure Supabase Storage bucket exists and is public
4. Check server logs for error messages
5. Verify .env file has correct Supabase credentials

## Summary

This implementation successfully adds background image support for a Tinder-like hangout experience. All code has been tested for syntax validity and security vulnerabilities (0 alerts found). The server is ready for deployment after running the database migration.

**Total Files Changed:** 7 (6 modified/created, 1 documentation)
**Lines Changed:** ~400 lines added
**Security Vulnerabilities:** 0
**Breaking Changes:** 1 (GET /hangouts endpoint behavior)
