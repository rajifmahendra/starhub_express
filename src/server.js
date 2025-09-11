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
      'http://54.179.2.8:4001', // Frontend port
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

// CORS middleware - harus di atas semua routes
app.use((req, res, next) => {
  const origin = req.headers.origin;
  
  // Log all requests for debugging
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - Origin: ${origin || 'none'}`);
  
  // Handle preflight requests first
  if (req.method === 'OPTIONS') {
    console.log('Handling preflight request for:', req.path);
    
    // Set CORS headers for preflight
    if (origin) {
      const allowedOrigins = process.env.ALLOWED_ORIGINS 
        ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
        : [
            'http://localhost:3000', 'http://localhost:3001', 'http://localhost:8080',
            'http://127.0.0.1:3000', 'http://127.0.0.1:3001', 'http://127.0.0.1:8080',
            'http://54.179.2.8:3000', 'http://54.179.2.8:3001', 'http://54.179.2.8:4001', 'http://54.179.2.8:8080'
          ];
      
      if (allowedOrigins.includes(origin) || process.env.NODE_ENV === 'development') {
        res.header('Access-Control-Allow-Origin', origin);
        res.header('Access-Control-Allow-Credentials', 'true');
        res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
        res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
        res.header('Access-Control-Max-Age', '86400'); // 24 hours
        console.log('CORS preflight allowed for origin:', origin);
      } else {
        console.log('CORS preflight blocked for origin:', origin);
        return res.status(403).json({ error: 'CORS policy violation' });
      }
    }
    
    return res.status(200).end();
  }
  
  // Handle actual requests
  if (origin) {
    const allowedOrigins = process.env.ALLOWED_ORIGINS 
      ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
      : [
          'http://localhost:3000', 'http://localhost:3001', 'http://localhost:8080',
          'http://127.0.0.1:3000', 'http://127.0.0.1:3001', 'http://127.0.0.1:8080',
          'http://54.179.2.8:3000', 'http://54.179.2.8:3001', 'http://54.179.2.8:4001', 'http://54.179.2.8:8080'
        ];
    
    if (allowedOrigins.includes(origin) || process.env.NODE_ENV === 'development') {
      res.header('Access-Control-Allow-Origin', origin);
      res.header('Access-Control-Allow-Credentials', 'true');
      console.log('CORS request allowed for origin:', origin);
    } else {
      console.log('CORS request blocked for origin:', origin);
      return res.status(403).json({ error: 'CORS policy violation' });
    }
  }
  
  next();
});

// Apply CORS middleware as backup
app.use(cors(corsOptions));

app.use(express.json());

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
