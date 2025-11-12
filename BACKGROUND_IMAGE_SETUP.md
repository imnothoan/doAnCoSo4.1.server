# Background Image Feature Setup Guide

This guide explains how to set up the background image feature for the Tinder-like hangout functionality.

## 1. Database Migration

Run the following SQL in your Supabase SQL Editor:

```sql
-- Add background_image column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS background_image TEXT;

-- Create index to improve query performance
CREATE INDEX IF NOT EXISTS idx_users_background_image ON users(background_image) WHERE background_image IS NOT NULL;
```

Alternatively, you can run the migration file:
```bash
# Execute the migration in Supabase SQL Editor
# File: db/migrations/add_background_image.sql
```

## 2. Create Supabase Storage Bucket

You have two options to create the `background-images` bucket:

### Option A: Via Supabase Dashboard (Recommended)

1. Log in to your [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **Storage** (left sidebar)
4. Click **"Create a new bucket"**
5. Configure the bucket:
   - **Name**: `background-images`
   - **Public bucket**: ✅ Yes (images need to be publicly accessible)
   - **File size limit**: `10485760` (10MB)
   - **Allowed MIME types**: `image/jpeg, image/png, image/jpg`
6. Click **"Create bucket"**

### Option B: Programmatically (Automatic on Server Start)

The server will automatically attempt to create the bucket on startup. No manual action required.

If you want to manually trigger bucket creation, you can run:

```javascript
const { supabase } = require('./db/supabaseClient');

async function createBackgroundImagesBucket() {
  const { data, error } = await supabase
    .storage
    .createBucket('background-images', {
      public: true,
      fileSizeLimit: 10485760, // 10MB
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/jpg']
    });

  if (error && !error.message.includes('already exists')) {
    console.error('Error creating bucket:', error);
  } else {
    console.log('Background images bucket ready!');
  }
}

createBackgroundImagesBucket();
```

## 3. API Endpoints

### Upload Background Image
```
POST /users/:userId/background-image
Content-Type: multipart/form-data

FormData:
  - background_image: <file>
```

**Response:**
```json
{
  "backgroundImageUrl": "https://[project].supabase.co/storage/v1/object/public/background-images/[filename]"
}
```

### Get User with Background Image

All user endpoints now return the `background_image` field:

- `GET /users/id/:id`
- `GET /users/username/:username`
- `GET /users/:id` (UUID format)
- `GET /hangouts` (returns online users with background images)

**Example Response:**
```json
{
  "id": "uuid",
  "username": "johndoe",
  "name": "John Doe",
  "avatar": "https://...",
  "background_image": "https://...",
  "is_online": true,
  ...
}
```

## 4. Hangout Feature

The `/hangouts` endpoint has been updated to:
- Return only **online users** (`is_online = true`)
- Include the `background_image` field for all users
- Support existing filters (languages, distance)

**Example Request:**
```
GET /hangouts?limit=50&languages=English,Vietnamese&distance_km=10&user_lat=10.762622&user_lng=106.660172
```

**Example Response:**
```json
[
  {
    "id": "user-uuid",
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
    "longitude": 106.660172
  },
  ...
]
```

## 5. Testing

### Test Background Image Upload

```bash
# Upload background image for user
curl -X POST http://localhost:3000/users/[USER_ID]/background-image \
  -F "background_image=@/path/to/image.jpg"
```

### Test Hangout Endpoint

```bash
# Get online users with background images
curl "http://localhost:3000/hangouts?limit=50"
```

## 6. Client Integration

On the client side (React Native), you can use the background image like this:

```javascript
// Upload background image
const uploadBackgroundImage = async (userId, imageUri) => {
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

  return await response.json();
};

// Display in Tinder-like card
<ImageBackground 
  source={{ uri: user.background_image }} 
  style={styles.backgroundImage}
>
  <LinearGradient
    colors={['transparent', 'rgba(0,0,0,0.8)']}
    style={styles.gradient}
  >
    <Text style={styles.name}>{user.name}</Text>
    <Text style={styles.bio}>{user.bio}</Text>
  </LinearGradient>
</ImageBackground>
```

## 7. Security Considerations

- Only authenticated users can upload background images
- File size is limited to 10MB
- Only image formats (JPEG, PNG, JPG) are allowed
- Images are stored in a public bucket (URLs are accessible without authentication)
- Old images are not automatically deleted when uploading a new one (consider implementing cleanup if needed)

## 8. Troubleshooting

### Bucket Already Exists Error
If you see "Bucket already exists" error, this is normal and can be ignored.

### Upload Fails
- Check file size (must be ≤ 10MB)
- Verify file format (JPEG, PNG, JPG only)
- Ensure the bucket exists and is public
- Check Supabase service role key permissions

### Images Not Displaying
- Verify the bucket is set to **public**
- Check the URL returned from the upload endpoint
- Ensure CORS is configured correctly in Supabase Storage settings
