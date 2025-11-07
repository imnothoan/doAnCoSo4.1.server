const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const http = require('http');
const { Dropbox } = require('dropbox');
const mysql = require('mysql2/promise');

dotenv.config({ path: '.env' });

const app = express();
const server = http.createServer(app);  // Create server for express


const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Set up DB connection (MySQL)
const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

// Set up Dropbox SDK
const dbx = new Dropbox({
  accessToken: process.env.DROPBOX_ACCESS_TOKEN,
  fetch: global.fetch,
});

// Routes
const userRoutes = require('./routes/user.routes');
const authRoutes = require('./routes/auth.routes');
const postRoutes = require('./routes/post.routes');

app.use('/users', userRoutes);
app.use('/auth', authRoutes);
app.use("/posts", postRoutes);

server.listen(PORT, () => {
  console.log(`🚀 Server express socket đang chạy tại http://localhost:${PORT}`);
});