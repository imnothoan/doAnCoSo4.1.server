const express = require("express");
const multer = require("multer");
const router = express.Router();
const { supabase } = require("../db/supabaseClient");
const upload = multer({ storage: multer.memoryStorage() });

// ----------------------------- Utilities & Helpers -----------------------------

async function getPostById(postId) {
  const { data, error } = await supabase
    .from("posts")
    .select(
      "id, author_username, content, status, audience, disable_comments, hide_like_count, like_count, comment_count, created_at, updated_at, post_media(id, media_url, media_type, position, created_at)"
    )
    .eq("id", postId)
    .single();
  if (error) throw error;
  return data || null;
}

async function updateLikeCount(postId) {
  const { count, error } = await supabase
    .from("post_likes")
    .select("id", { count: "exact", head: true })
    .eq("post_id", postId);
  if (error) throw error;

  const upd = await supabase.from("posts").update({ like_count: count || 0 }).eq("id", postId);
  if (upd.error) throw upd.error;
  return count || 0;
}

async function updateCommentCount(postId) {
  const { count, error } = await supabase
    .from("comments")
    .select("id", { count: "exact", head: true })
    .eq("post_id", postId);
  if (error) throw error;

  const upd = await supabase.from("posts").update({ comment_count: count || 0 }).eq("id", postId);
  if (upd.error) throw upd.error;
  return count || 0;
}

function isDuplicateKeyError(err) {
  if (!err) return false;
  const msg = String(err.message || "").toLowerCase();
  return msg.includes("duplicate") || msg.includes("unique constraint");
}

// ------------------------------- Create a post --------------------------------

/**
 * Create a post with optional media files
 * POST /posts
 * Multipart form-data:
 *  - fields: author_username, content?, status?, audience? ('public'|'followers'|'close_friends'|'private'),
 *            disable_comments?(boolean), hide_like_count?(boolean)
 *  - files: media (can upload multiple) -> each file stored in bucket 'posts'
 */
router.post("/", upload.array("media", 10), async (req, res) => {
  try {
    const {
      author_username,
      content = null,
      status = null,
      audience = "followers",
      disable_comments = "false",
      hide_like_count = "false",
    } = req.body;

    if (!author_username) {
      return res.status(400).json({ message: "Missing author_username." });
    }

    // 1) Insert post
    const { data: post, error: postErr } = await supabase
      .from("posts")
      .insert([
        {
          author_username,
          content,
          status,
          audience,
          disable_comments: String(disable_comments) === "true",
          hide_like_count: String(hide_like_count) === "true",
        },
      ])
      .select("*")
      .single();

    if (postErr) throw postErr;

    // 2) Upload media (if any)
    const files = req.files || [];
    const mediaRows = [];

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const cleanName = file.originalname.replace(/[^\w.\-]+/g, "_");
      const storagePath = `posts/${post.id}/${Date.now()}_${i}_${cleanName}`;

      const uploadRes = await supabase.storage
        .from("posts")
        .upload(storagePath, file.buffer, { contentType: file.mimetype, upsert: true });

      if (uploadRes.error) throw uploadRes.error;

      const { data: pub } = supabase.storage.from("posts").getPublicUrl(storagePath);
      const media_url = pub.publicUrl;

      // Insert post_media row
      const { data: pm, error: pmErr } = await supabase
        .from("post_media")
        .insert([
          {
            post_id: post.id,
            media_url,
            media_type: file.mimetype.startsWith("video") ? "video" : "image",
            position: i,
          },
        ])
        .select("*")
        .single();
      if (pmErr) throw pmErr;

      mediaRows.push(pm);
    }

    // 3) Return full post with media
    const full = await getPostById(post.id);
    res.status(201).json(full);
  } catch (err) {
    console.error("create post error:", err);
    res.status(500).json({ message: "Server error while creating post." });
  }
});

// ------------------------------- Update a post --------------------------------

/**
 * Update a post (author only – basic check)
 * PUT /posts/:id
 * Body: { author_username, content?, status?, audience?, disable_comments?, hide_like_count? }
 */
router.put("/:id", async (req, res) => {
  const postId = Number(req.params.id);
  const {
    author_username,
    content,
    status,
    audience,
    disable_comments,
    hide_like_count,
  } = req.body;

  if (!author_username) return res.status(400).json({ message: "Missing author_username." });

  try {
    const current = await getPostById(postId);
    if (!current) return res.status(404).json({ message: "Post not found." });
    if (current.author_username !== author_username)
      return res.status(403).json({ message: "Not allowed to edit this post." });

    const { data, error } = await supabase
      .from("posts")
      .update({
        content,
        status,
        audience,
        disable_comments: typeof disable_comments === "boolean" ? disable_comments : undefined,
        hide_like_count: typeof hide_like_count === "boolean" ? hide_like_count : undefined,
        updated_at: new Date().toISOString(),
      })
      .eq("id", postId)
      .select("*")
      .single();

    if (error) throw error;
    const full = await getPostById(data.id);
    res.json(full);
  } catch (err) {
    console.error("update post error:", err);
    res.status(500).json({ message: "Server error while updating post." });
  }
});

// ------------------------------- Delete a post --------------------------------

/**
 * Delete a post (author only – basic check)
 * DELETE /posts/:id
 * Body: { author_username }
 */
router.delete("/:id", async (req, res) => {
  const postId = Number(req.params.id);
  const { author_username } = req.body;

  if (!author_username) return res.status(400).json({ message: "Missing author_username." });

  try {
    const current = await getPostById(postId);
    if (!current) return res.status(404).json({ message: "Post not found." });
    if (current.author_username !== author_username)
      return res.status(403).json({ message: "Not allowed to delete this post." });

    // Delete rows in post_media/comments/likes cascade via FK (DB handles it)
    const del = await supabase.from("posts").delete().eq("id", postId);
    if (del.error) throw del.error;

    res.json({ message: "Post deleted." });
  } catch (err) {
    console.error("delete post error:", err);
    res.status(500).json({ message: "Server error while deleting post." });
  }
});

// ------------------------------ Attach more media -----------------------------

/**
 * Add media to an existing post
 * POST /posts/:id/media
 * Files: media (multi)
 * Body: { author_username }
 */
router.post("/:id/media", upload.array("media", 10), async (req, res) => {
  const postId = Number(req.params.id);
  const { author_username } = req.body;

  if (!author_username) return res.status(400).json({ message: "Missing author_username." });

  try {
    const current = await getPostById(postId);
    if (!current) return res.status(404).json({ message: "Post not found." });
    if (current.author_username !== author_username)
      return res.status(403).json({ message: "Not allowed to add media to this post." });

    const basePos = (current.post_media || []).length;
    const files = req.files || [];
    const added = [];

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const cleanName = file.originalname.replace(/[^\w.\-]+/g, "_");
      const storagePath = `posts/${postId}/${Date.now()}_${i}_${cleanName}`;

      const uploadRes = await supabase.storage
        .from("posts")
        .upload(storagePath, file.buffer, { contentType: file.mimetype, upsert: true });
      if (uploadRes.error) throw uploadRes.error;

      const { data: pub } = supabase.storage.from("posts").getPublicUrl(storagePath);
      const media_url = pub.publicUrl;

      const { data: pm, error: pmErr } = await supabase
        .from("post_media")
        .insert([
          {
            post_id: postId,
            media_url,
            media_type: file.mimetype.startsWith("video") ? "video" : "image",
            position: basePos + i,
          },
        ])
        .select("*")
        .single();
      if (pmErr) throw pmErr;

      added.push(pm);
    }

    const full = await getPostById(postId);
    res.json(full);
  } catch (err) {
    console.error("add media error:", err);
    res.status(500).json({ message: "Server error while adding media." });
  }
});

/**
 * Remove a media row
 * DELETE /posts/:id/media/:mediaId
 * Body: { author_username }
 */
router.delete("/:id/media/:mediaId", async (req, res) => {
  const postId = Number(req.params.id);
  const mediaId = Number(req.params.mediaId);
  const { author_username } = req.body;

  if (!author_username) return res.status(400).json({ message: "Missing author_username." });

  try {
    const current = await getPostById(postId);
    if (!current) return res.status(404).json({ message: "Post not found." });
    if (current.author_username !== author_username)
      return res.status(403).json({ message: "Not allowed to remove media from this post." });

    const del = await supabase.from("post_media").delete().eq("id", mediaId).eq("post_id", postId);
    if (del.error) throw del.error;

    // Optionally re-number positions here if you need strict ordering continuity.

    const full = await getPostById(postId);
    res.json(full);
  } catch (err) {
    console.error("remove media error:", err);
    res.status(500).json({ message: "Server error while removing media." });
  }
});

// ---------------------------------- Get posts ---------------------------------

/**
 * Public feed (or simple list) with pagination
 * GET /posts?limit=20&before=<ISO date>
 * Optional: viewer=<username> (future: privacy logic; currently returns public + all)
 */
router.get("/", async (req, res) => {
  const limit = Math.min(Number(req.query.limit || 20), 50);
  const before = req.query.before ? new Date(req.query.before).toISOString() : null;

  try {
    let query = supabase
      .from("posts")
      .select(
        "id, author_username, content, status, audience, disable_comments, hide_like_count, like_count, comment_count, created_at, updated_at, post_media(id, media_url, media_type, position)"
      )
      .order("created_at", { ascending: false })
      .limit(limit);

    if (before) {
      query = query.lt("created_at", before);
    }

    const { data, error } = await query;
    if (error) throw error;

    res.json(data || []);
  } catch (err) {
    console.error("list posts error:", err);
    res.status(500).json({ message: "Server error while listing posts." });
  }
});

/**
 * Get a single post by id
 * GET /posts/:id
 * Optional: viewer=<username> to include is_liked_by_viewer
 */
router.get("/:id", async (req, res) => {
  const postId = Number(req.params.id);
  const viewer = (req.query.viewer || "").trim();

  try {
    const post = await getPostById(postId);
    if (!post) return res.status(404).json({ message: "Post not found." });

    if (viewer) {
      const { data: liked, error: lErr } = await supabase
        .from("post_likes")
        .select("id")
        .eq("post_id", postId)
        .eq("username", viewer)
        .limit(1);
      if (lErr) throw lErr;
      return res.json({ ...post, is_liked_by_viewer: !!(liked && liked.length) });
    }

    res.json(post);
  } catch (err) {
    console.error("get post error:", err);
    res.status(500).json({ message: "Server error while fetching post." });
  }
});

/**
 * Get posts by author
 * GET /posts/user/:username?limit=20&before=<ISO date>
 */
router.get("/user/:username", async (req, res) => {
  const { username } = req.params;
  const limit = Math.min(Number(req.query.limit || 20), 50);
  const before = req.query.before ? new Date(req.query.before).toISOString() : null;

  try {
    let query = supabase
      .from("posts")
      .select(
        "id, author_username, content, status, audience, disable_comments, hide_like_count, like_count, comment_count, created_at, updated_at, post_media(id, media_url, media_type, position)"
      )
      .eq("author_username", username)
      .order("created_at", { ascending: false })
      .limit(limit);

    if (before) {
      query = query.lt("created_at", before);
    }

    const { data, error } = await query;
    if (error) throw error;

    res.json(data || []);
  } catch (err) {
    console.error("user posts error:", err);
    res.status(500).json({ message: "Server error while fetching user posts." });
  }
});

// --------------------------------- Likes APIs ---------------------------------

/**
 * Like a post
 * POST /posts/:id/like
 * Body: { username }
 */
router.post("/:id/like", async (req, res) => {
  const postId = Number(req.params.id);
  const { username } = req.body;

  if (!username) return res.status(400).json({ message: "Missing username." });

  try {
    const ins = await supabase
      .from("post_likes")
      .insert([{ post_id: postId, username }])
      .select("*")
      .single();

    if (ins.error && !isDuplicateKeyError(ins.error)) throw ins.error;

    const newCount = await updateLikeCount(postId);
    res.json({ post_id: postId, liked_by: username, like_count: newCount, duplicated: !!ins.error });
  } catch (err) {
    console.error("like post error:", err);
    res.status(500).json({ message: "Server error while liking post." });
  }
});

/**
 * Unlike a post
 * DELETE /posts/:id/like
 * Body: { username }
 */
router.delete("/:id/like", async (req, res) => {
  const postId = Number(req.params.id);
  const { username } = req.body;

  if (!username) return res.status(400).json({ message: "Missing username." });

  try {
    const del = await supabase.from("post_likes").delete().eq("post_id", postId).eq("username", username);
    if (del.error) throw del.error;

    const newCount = await updateLikeCount(postId);
    res.json({ post_id: postId, unliked_by: username, like_count: newCount });
  } catch (err) {
    console.error("unlike post error:", err);
    res.status(500).json({ message: "Server error while unliking post." });
  }
});

/**
 * Get likes of a post
 * GET /posts/:id/likes?withProfiles=true
 */
router.get("/:id/likes", async (req, res) => {
  const postId = Number(req.params.id);
  const withProfiles = String(req.query.withProfiles || "false") === "true";

  try {
    const { data: likes, error } = await supabase
      .from("post_likes")
      .select("username, created_at")
      .eq("post_id", postId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    if (!withProfiles) return res.json(likes);

    const usernames = likes.map((l) => l.username);
    if (!usernames.length) return res.json([]);

    const { data: profiles, error: pErr } = await supabase
      .from("users")
      .select("id, username, name, avatar, bio")
      .in("username", usernames);
    if (pErr) throw pErr;

    // map by username
    const map = new Map(profiles.map((u) => [u.username, u]));
    res.json(likes.map((l) => ({ ...l, user: map.get(l.username) || null })));
  } catch (err) {
    console.error("list likes error:", err);
    res.status(500).json({ message: "Server error while fetching likes." });
  }
});

// ------------------------------- Comments APIs --------------------------------

/**
 * Add a comment
 * POST /posts/:id/comments
 * Body: { author_username, content, parent_id? }
 */
router.post("/:id/comments", async (req, res) => {
  const postId = Number(req.params.id);
  const { author_username, content, parent_id = null } = req.body;

  if (!author_username || !content) {
    return res.status(400).json({ message: "Missing author_username or content." });
  }

  try {
    const { data, error } = await supabase
      .from("comments")
      .insert([{ post_id: postId, author_username, content, parent_id }])
      .select("*")
      .single();
    if (error) throw error;

    await updateCommentCount(postId);
    res.status(201).json(data);
  } catch (err) {
    console.error("add comment error:", err);
    res.status(500).json({ message: "Server error while adding comment." });
  }
});

/**
 * Get comments for a post (root or by parent)
 * GET /posts/:id/comments?parent_id=<id|null>
 *  - parent_id omitted => root comments (parent_id IS NULL)
 *  - parent_id=<id>     => replies of that parent
 */
router.get("/:id/comments", async (req, res) => {
  const postId = Number(req.params.id);
  const hasParent = typeof req.query.parent_id !== "undefined";
  const parentId = req.query.parent_id === "null" ? null : Number(req.query.parent_id);

  try {
    let query = supabase
      .from("comments")
      .select("id, post_id, author_username, content, parent_id, like_count, created_at, updated_at")
      .eq("post_id", postId)
      .order("created_at", { ascending: true });

    if (hasParent) {
      if (parentId === null) query = query.is("parent_id", null);
      else query = query.eq("parent_id", parentId);
    } else {
      query = query.is("parent_id", null);
    }

    const { data, error } = await query;
    if (error) throw error;

    res.json(data || []);
  } catch (err) {
    console.error("list comments error:", err);
    res.status(500).json({ message: "Server error while fetching comments." });
  }
});

/**
 * Delete a comment (author only – basic check)
 * DELETE /posts/:id/comments/:commentId
 * Body: { author_username }
 */
router.delete("/:id/comments/:commentId", async (req, res) => {
  const postId = Number(req.params.id);
  const commentId = Number(req.params.commentId);
  const { author_username } = req.body;

  if (!author_username) return res.status(400).json({ message: "Missing author_username." });

  try {
    // Fetch comment to verify ownership
    const { data: cmt, error: cErr } = await supabase
      .from("comments")
      .select("id, author_username, post_id")
      .eq("id", commentId)
      .single();
    if (cErr) throw cErr;
    if (!cmt) return res.status(404).json({ message: "Comment not found." });
    if (cmt.author_username !== author_username)
      return res.status(403).json({ message: "Not allowed to delete this comment." });

    // Delete the comment (replies cascade by FK if parent_id constraint is ON DELETE CASCADE)
    const del = await supabase.from("comments").delete().eq("id", commentId);
    if (del.error) throw del.error;

    await updateCommentCount(postId);
    res.json({ message: "Comment deleted." });
  } catch (err) {
    console.error("delete comment error:", err);
    res.status(500).json({ message: "Server error while deleting comment." });
  }
});

module.exports = router;
