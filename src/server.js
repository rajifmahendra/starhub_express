import express from "express";
import dotenv from "dotenv";
import authRoutes from "./routes/authRoutes.js"
import orderRoutes from "./routes/orderRoutes.js"
import path from "path";
import { fileURLToPath } from 'url';
import cors from 'cors';


dotenv.config();

const app = express();

// CORS configuration untuk production deployment
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps, curl, or server-to-server requests)
    if (!origin) return callback(null, true);
    
    // Get allowed origins from environment variable or use defaults
    const allowedOriginsEnv = process.env.ALLOWED_ORIGINS;
    const defaultOrigins = [
      'http://localhost:3000',
      'http://localhost:3001', 
      'http://localhost:8080',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:3001',
      'http://127.0.0.1:8080',
      // Add your frontend domain here
      'http://54.179.2.8:3000',
      'http://54.179.2.8:3001',
      'http://54.179.2.8:8080',
      // Add production domains
      'https://yourdomain.com',
      'https://www.yourdomain.com'
    ];
    
    const allowedOrigins = allowedOriginsEnv 
      ? allowedOriginsEnv.split(',').map(origin => origin.trim())
      : defaultOrigins;
    
    // Check if origin is in allowed list
    if (allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    }
    
    // For development, allow all origins
    if (process.env.NODE_ENV === 'development') {
      return callback(null, true);
    }
    
    // For production, be more restrictive
    console.log('CORS blocked origin:', origin);
    console.log('Allowed origins:', allowedOrigins);
    return callback(new Error('Not allowed by CORS'), false);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization', 
    'X-Requested-With', 
    'Accept', 
    'Origin',
    'Access-Control-Request-Method',
    'Access-Control-Request-Headers'
  ],
  exposedHeaders: ['Authorization'],
  optionsSuccessStatus: 200, // Some legacy browsers choke on 204
  preflightContinue: false
};

app.use(cors(corsOptions));

// Handle preflight requests explicitly
app.options('*', cors(corsOptions));

app.use(express.json());

// Add middleware untuk logging CORS issues
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (origin && process.env.NODE_ENV === 'production') {
    console.log(`Request from origin: ${origin}`);
  }
  next();
});

app.use("/api/auth", authRoutes);

app.use("/api/order", orderRoutes);
const PORT = process.env.PORT || 5000;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.get('/swagger.json', (req, res) => {
  const filePath = path.join(__dirname, 'swagger-output.json');
  res.sendFile(filePath);  // Kirimkan file .json
});

app.get('/swagger.yaml', (req, res) => {
  const filePath = path.join(__dirname, 'swagger-output.yaml');
  res.sendFile(filePath);  // Kirimkan file .json
});
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
