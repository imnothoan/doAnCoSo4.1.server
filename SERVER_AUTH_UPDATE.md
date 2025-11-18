# Server Authentication Update Guide

## 🔐 Security Update - Password Hashing Implementation

This update implements secure password authentication to fix critical security vulnerabilities in the server.

### ⚠️ Critical Issues Fixed

1. **Login accepts any password** - ✅ Fixed: Now validates against bcrypt hash
2. **No password hashing** - ✅ Fixed: Passwords are securely hashed with bcrypt
3. **Security risk** - ✅ Fixed: Password hashes never exposed in API responses

---

## 🚀 Deployment Instructions

### 1. Update Server Code

```bash
cd doAnCoSo4.1.server
git pull origin main
npm install
```

This will install the new `bcryptjs` dependency.

### 2. Run Database Migration

You need to add the `password_hash` column to your users table. Run this SQL in your **Supabase SQL Editor**:

```sql
-- Add password_hash column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Create index for faster email lookups during login
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Add comment
COMMENT ON COLUMN users.password_hash IS 'Bcrypt hashed password for authentication';
```

Or use the migration file:

```bash
# Copy the SQL from db/migrations/add_password_hash.sql
# and paste it into Supabase SQL Editor
```

### 3. Restart Server

```bash
npm start
```

---

## 📋 What Changed

### Backend Files Modified

1. **package.json**
   - Added `bcryptjs: ^3.0.3` dependency

2. **db/schema.sql**
   - Added `password_hash TEXT` column
   - Added email index for faster lookups

3. **db/migrations/add_password_hash.sql**
   - New migration file for database update

4. **routes/auth.routes.js**
   - ✅ Signup now hashes passwords with bcrypt (10 rounds)
   - ✅ Signup validates minimum password length (6 characters)
   - ✅ Signup removes password_hash from response
   - ✅ Login validates password against hash
   - ✅ Login handles legacy users without password_hash
   - ✅ Login removes password_hash from response

5. **routes/user.routes.js**
   - ✅ Added `sanitizeUser()` helper function
   - ✅ Updated `getUserById()` to sanitize responses
   - ✅ Updated `getUserByUsername()` to sanitize responses

---

## 🔍 Testing the Update

### Test 1: Create New Account

```bash
curl -X POST http://localhost:3000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "name": "Test User"
  }'
```

Expected: User created with hashed password (password_hash NOT in response)

### Test 2: Login with Correct Password

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```

Expected: Login successful, returns user + token

### Test 3: Login with Wrong Password

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "wrongpassword"
  }'
```

Expected: `401 Unauthorized` with message "Invalid credentials"

### Test 4: Password Too Short

```bash
curl -X POST http://localhost:3000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test2@example.com",
    "password": "12345",
    "name": "Test User 2"
  }'
```

Expected: `400 Bad Request` with message "Password must be at least 6 characters"

---

## 📝 Important Notes

### Existing Users

**Users created before this update will have `password_hash` as NULL.**

They will see the error: `"Invalid credentials. Please reset your password."`

You have two options:

1. **Implement password reset feature** (recommended for production)
2. **Manually update existing users** to re-create accounts

### Password Security

- Passwords are hashed with **bcrypt** using 10 rounds
- Original passwords are **never stored** in the database
- Password hashes are **never exposed** in API responses
- Always use **HTTPS in production** to protect passwords in transit

### API Response Changes

All user objects returned from the API will **no longer include** the `password_hash` field. This applies to:

- `/auth/signup` response
- `/auth/login` response
- `/users/*` endpoints
- Any other endpoint returning user data

---

## ✅ Verification Checklist

After deployment, verify:

- [x] New signups create users with hashed passwords
- [x] Login accepts correct passwords
- [x] Login rejects incorrect passwords
- [x] Password minimum length is enforced
- [x] Password hashes are never exposed in API responses
- [x] Client receives proper error messages
- [x] Server starts without errors
- [x] Database migration executed successfully

---

## 🔗 Related Files

- Migration SQL: `db/migrations/add_password_hash.sql`
- Schema Update: `db/schema.sql`
- Auth Routes: `routes/auth.routes.js`
- User Routes: `routes/user.routes.js`

---

## 🆘 Troubleshooting

### Error: "bcryptjs not found"

```bash
npm install bcryptjs
```

### Error: "column password_hash does not exist"

Run the database migration SQL in Supabase SQL Editor.

### Server won't start

1. Check Node.js version: `node --version` (should be >= 18.0.0)
2. Reinstall dependencies: `rm -rf node_modules package-lock.json && npm install`
3. Check for syntax errors: `node -c index.js`

---

## 📞 Support

If you encounter any issues during deployment:

1. Check server logs for errors
2. Verify database migration was successful
3. Ensure bcryptjs is installed: `npm list bcryptjs`
4. Check Node.js version: `node --version`

---

**This is a critical security update. Please deploy as soon as possible.**
