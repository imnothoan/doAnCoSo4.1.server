const express = require('express');
const router = express.Router();
const { supabase } = require('../db/supabaseClient');
const { randomUUID } = require('crypto');

/**
 * Đăng ký user mới (Sync from Supabase Auth)
 * POST /auth/signup
 * Body: { id, email, name, country, city, username, gender }
 */
router.post('/signup', async (req, res) => {
  const { id, name, email, country, city, username: customUsername, gender } = req.body;

  // We expect an ID from Supabase Auth
  if (!id || !email) return res.status(400).json({ message: 'Missing id or email' });

  try {
    // Check if username exists (if provided)
    // If not provided, generate one
    const username = customUsername || (email.split('@')[0].replace(/[^a-zA-Z0-9_]/g, '') + '_' + Math.floor(Math.random() * 1000));

    // Insert into public users table
    const { data: inserted, error: insErr } = await supabase
      .from('users')
      .insert([{
        id,
        email,
        username,
        name: name || username,
        country: country || null,
        city: city || null,
        gender: gender || null,
        email_confirmed: false
      }])
      .select('*')
      .single();

    if (insErr) {
      // If duplicate username, we might want to retry with a new username if it was auto-generated
      // But for now just throw
      throw insErr;
    }

    // Create default hangout status for new user (visible by default)
    try {
      await supabase
        .from('user_hangout_status')
        .insert([{
          username: inserted.username,
          is_available: true, // Auto-enable visibility for new users
          current_activity: null,
          activities: []
        }]);
      console.log(`✅ Created default hangout status for ${inserted.username}`);
    } catch (hangoutErr) {
      // Non-critical - log but don't fail signup
      console.error('Warning: Could not create hangout status:', hangoutErr);
    }

    // Return user
    res.json({
      user: inserted,
      // No token needed here as client already has it from Supabase
    });
  } catch (err) {
    console.error('Signup error:', err);
    res.status(500).json({ message: 'Server error during signup sync' });
  }
});

/**
 * Đăng nhập (Deprecated - Client uses Supabase Auth directly)
 * POST /auth/login
 */
router.post('/login', async (req, res) => {
  res.status(410).json({ message: 'This endpoint is deprecated. Use Supabase Auth on client.' });
});

/**
 * POST /auth/logout
 * Không làm gì đặc biệt (client tự xóa token)
 */
router.post('/logout', (_req, res) => {
  res.json({ message: 'Logged out' });
});

module.exports = router;