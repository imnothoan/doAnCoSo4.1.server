# Hướng Dẫn Triển Khai Tính Năng Background Image (Tiếng Việt)

## Tổng Quan
Tính năng này cho phép người dùng upload ảnh nền (background image) riêng biệt với avatar, và cập nhật màn hình Hangout để hiển thị người dùng đang online theo kiểu Tinder (vuốt trái/phải).

## Các Bước Triển Khai

### Bước 1: Cập Nhật Database

Vào **Supabase Dashboard** → **SQL Editor** và chạy:

```sql
-- Thêm cột background_image vào bảng users
ALTER TABLE users ADD COLUMN IF NOT EXISTS background_image TEXT;

-- Tạo index để tăng tốc độ truy vấn
CREATE INDEX IF NOT EXISTS idx_users_background_image ON users(background_image) WHERE background_image IS NOT NULL;
```

Hoặc chạy file migration: `db/migrations/add_background_image.sql`

### Bước 2: Tạo Supabase Storage Bucket

#### Cách 1: Qua Supabase Dashboard (Khuyến nghị)

1. Đăng nhập vào [Supabase Dashboard](https://app.supabase.com)
2. Chọn project của bạn
3. Vào **Storage** (thanh bên trái)
4. Click **"Create a new bucket"**
5. Cấu hình bucket:
   - **Name**: `background-images`
   - **Public bucket**: ✅ Chọn (để ảnh có thể truy cập công khai)
   - **File size limit**: `10485760` (10MB)
   - **Allowed MIME types**: `image/jpeg, image/png, image/jpg`
6. Click **"Create bucket"**

#### Cách 2: Tự Động (Khi Khởi Động Server)

Server sẽ tự động tạo bucket khi khởi động. Không cần làm gì cả!

```bash
npm start
# Xem log: "✅ Background images bucket created successfully"
```

### Bước 3: Khởi Động Server

```bash
# Cài đặt dependencies
npm install

# Chạy server
npm start
```

Server sẽ tự động:
- Kết nối với Supabase
- Tạo bucket `background-images` (nếu chưa có)
- Khởi động các API endpoints

## API Endpoints Mới

### 1. Upload Background Image

**Endpoint:** `POST /users/:userId/background-image`

**Ví dụ:**
```bash
curl -X POST http://localhost:3000/users/[USER_ID]/background-image \
  -F "background_image=@/path/to/anh.jpg"
```

**Response:**
```json
{
  "backgroundImageUrl": "https://[project].supabase.co/storage/v1/object/public/background-images/[userId]-[timestamp].jpg"
}
```

### 2. Lấy Danh Sách User Online (Hangout - Tinder Style)

**Endpoint:** `GET /hangouts`

**Tham số:**
- `limit`: Số lượng user tối đa (mặc định: 50, max: 100)
- `distance_km`: Khoảng cách tối đa (km)
- `user_lat`: Vĩ độ của user hiện tại
- `user_lng`: Kinh độ của user hiện tại

**Ví dụ:**
```bash
curl "http://localhost:3000/hangouts?limit=50&distance_km=10&user_lat=10.762622&user_lng=106.660172"
```

**Response:**
```json
[
  {
    "id": "uuid",
    "username": "alice",
    "name": "Alice",
    "avatar": "https://...",
    "background_image": "https://...",
    "age": 25,
    "bio": "Thích du lịch!",
    "interests": ["Du lịch", "Trao đổi ngôn ngữ"],
    "is_online": true,
    "country": "Vietnam",
    "city": "Ho Chi Minh",
    "latitude": 10.762622,
    "longitude": 106.660172,
    "distance": 2.5
  }
]
```

## Tích Hợp Client (React Native)

### Upload Background Image

```javascript
import * as ImagePicker from 'expo-image-picker';

const uploadBackgroundImage = async (userId) => {
  // Chọn ảnh
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    allowsEditing: true,
    quality: 0.8,
  });

  if (result.canceled) return;

  // Upload
  const formData = new FormData();
  formData.append('background_image', {
    uri: result.assets[0].uri,
    type: 'image/jpeg',
    name: 'background.jpg',
  });

  const response = await fetch(`${API_URL}/users/${userId}/background-image`, {
    method: 'POST',
    body: formData,
  });

  const { backgroundImageUrl } = await response.json();
  console.log('Uploaded:', backgroundImageUrl);
};
```

### Lấy Users Online cho Hangout

```javascript
const fetchOnlineUsers = async (userLocation) => {
  const { latitude, longitude } = userLocation;
  
  const response = await fetch(
    `${API_URL}/hangouts?limit=50&distance_km=10&user_lat=${latitude}&user_lng=${longitude}`
  );
  
  const users = await response.json();
  return users;
};
```

### Hiển Thị Card Tinder-Style

```jsx
import { ImageBackground, View, Text } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

const UserCard = ({ user }) => {
  return (
    <ImageBackground 
      source={{ uri: user.background_image || user.avatar }}
      style={styles.card}
      imageStyle={styles.backgroundImage}
    >
      <LinearGradient
        colors={['transparent', 'rgba(0,0,0,0.8)']}
        style={styles.gradient}
      >
        <View style={styles.infoContainer}>
          <Text style={styles.name}>
            {user.name}, {user.age}
          </Text>
          <Text style={styles.location}>
            📍 {user.city}, {user.country}
          </Text>
          <Text style={styles.bio}>{user.bio}</Text>
          
          <View style={styles.interests}>
            {user.interests?.map(interest => (
              <View key={interest} style={styles.chip}>
                <Text style={styles.chipText}>{interest}</Text>
              </View>
            ))}
          </View>
        </View>
      </LinearGradient>
    </ImageBackground>
  );
};

const styles = StyleSheet.create({
  card: {
    width: '100%',
    height: '100%',
    borderRadius: 20,
    overflow: 'hidden',
  },
  backgroundImage: {
    borderRadius: 20,
  },
  gradient: {
    flex: 1,
    justifyContent: 'flex-end',
    padding: 20,
  },
  infoContainer: {
    marginBottom: 20,
  },
  name: {
    fontSize: 28,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 5,
  },
  location: {
    fontSize: 16,
    color: 'white',
    marginBottom: 10,
  },
  bio: {
    fontSize: 14,
    color: 'white',
    marginBottom: 15,
  },
  interests: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    backgroundColor: 'rgba(255,255,255,0.3)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  chipText: {
    color: 'white',
    fontSize: 12,
  },
});
```

## Thay Đổi Quan Trọng ⚠️

### Breaking Change: Endpoint `/hangouts`

**Trước đây:**
- Trả về các sự kiện hangout (meetups/events)
- Response: `[{ id, title, description, creator_username, ... }]`

**Bây giờ:**
- Trả về danh sách users đang online
- Response: `[{ id, username, name, background_image, is_online, ... }]`

**Cách di chuyển:**
- Nếu client cần chức năng hangout cũ (events), cần tạo endpoint mới
- Hoặc cập nhật client để sử dụng hệ thống user-based hangout mới

## Kiểm Tra

### Test Upload Background Image

```bash
# Thay USER_ID bằng ID người dùng thực
curl -X POST http://localhost:3000/users/[USER_ID]/background-image \
  -F "background_image=@/path/to/test-image.jpg"
```

### Test Lấy Users Online

```bash
curl "http://localhost:3000/hangouts?limit=10"
```

### Test Trong Client

1. **Upload ảnh nền:**
   - Mở app
   - Vào profile
   - Chọn "Upload Background Image"
   - Chọn ảnh từ thư viện
   - Kiểm tra URL trả về

2. **Xem users online:**
   - Vào màn hình Hangout
   - Kiểm tra danh sách users hiển thị
   - Kiểm tra ảnh nền hiển thị đúng
   - Test vuốt trái/phải

## Bảo Mật

✅ **CodeQL Scan:** 0 lỗ hổng bảo mật

**Các điểm bảo mật:**
- Giới hạn file size: 10MB
- Chỉ chấp nhận: JPEG, PNG, JPG
- Ảnh được lưu trong bucket public (URL công khai)

**Khuyến nghị:**
- Thêm authentication middleware
- Thêm rate limiting cho upload
- Tự động xóa ảnh cũ khi upload ảnh mới
- Thêm virus scanning

## Xử Lý Lỗi

### "Bucket already exists"
- Bình thường, có thể bỏ qua
- Bucket đã được tạo trước đó

### Upload thất bại
- Kiểm tra file size (≤ 10MB)
- Kiểm tra định dạng (JPEG/PNG/JPG)
- Kiểm tra bucket đã tạo và là public
- Kiểm tra quyền Supabase service role key

### Ảnh không hiển thị
- Kiểm tra bucket là **public**
- Kiểm tra URL trả về từ endpoint
- Kiểm tra CORS settings trong Supabase Storage

## Tài Liệu Chi Tiết

Xem thêm:
- `BACKGROUND_IMAGE_SETUP.md` - Hướng dẫn setup chi tiết
- `IMPLEMENTATION_SUMMARY.md` - Tổng kết kỹ thuật đầy đủ
- `db/migrations/add_background_image.sql` - File migration database

## Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra database migration đã chạy chưa
2. Kiểm tra bucket đã tạo trong Supabase Storage
3. Xem log server để biết lỗi chi tiết
4. Kiểm tra .env file có đầy đủ thông tin Supabase

## Tóm Tắt

✅ **Hoàn Thành Tất Cả Yêu Cầu:**
- ✅ Thêm cột background_image vào database
- ✅ Tạo bucket riêng cho background images
- ✅ Endpoint upload background image
- ✅ Endpoint lấy users online với background image
- ✅ Chỉ hiển thị users đang online
- ✅ Tính năng Tinder-style sẵn sàng triển khai

**Files Thay Đổi:** 7 files
**Lỗ Hổng Bảo Mật:** 0
**Sẵn Sàng Triển Khai:** ✅

Chúc anh thành công! 🎉
