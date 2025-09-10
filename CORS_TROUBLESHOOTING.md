# CORS Troubleshooting Guide - StarHub Express

## 🚨 Masalah CORS Setelah Deployment

CORS (Cross-Origin Resource Sharing) error sering terjadi setelah aplikasi di-deploy. Ini adalah panduan untuk mengatasi masalah CORS.

## 🔍 Gejala CORS Error

```
Access to fetch at 'http://54.179.2.8:4002/api/auth/login' from origin 'http://localhost:3000' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## 🛠 Solusi

### 1. Update Environment Variables

Set environment variable `ALLOWED_ORIGINS` dengan domain frontend Anda:

```bash
# Development
export ALLOWED_ORIGINS="http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000"

# Production
export ALLOWED_ORIGINS="http://54.179.2.8:3000,http://54.179.2.8:3001,https://yourdomain.com"
```

### 2. Update Docker Environment

Jika menggunakan Docker, tambahkan ke Dockerfile atau docker-compose:

```dockerfile
ENV ALLOWED_ORIGINS="http://localhost:3000,http://54.179.2.8:3000,https://yourdomain.com"
```

### 3. Development Mode

Untuk development, set NODE_ENV:

```bash
export NODE_ENV=development
```

## 🧪 Testing CORS

### Manual Test dengan curl

```bash
# Test preflight request
curl -X OPTIONS \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  http://54.179.2.8:4002/api/auth/login

# Test actual request
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
  http://54.179.2.8:4002/api/auth/login
```

### Menggunakan Test Script

```bash
# Run CORS test script
chmod +x scripts/test-cors.sh
./scripts/test-cors.sh
```

## 🔧 Konfigurasi CORS yang Benar

### Server Configuration (src/server.js)

```javascript
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin
    if (!origin) return callback(null, true);
    
    const allowedOrigins = process.env.ALLOWED_ORIGINS 
      ? process.env.ALLOWED_ORIGINS.split(',').map(origin => origin.trim())
      : defaultOrigins;
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    }
    
    // Development mode - allow all
    if (process.env.NODE_ENV === 'development') {
      return callback(null, true);
    }
    
    console.log('CORS blocked origin:', origin);
    return callback(new Error('Not allowed by CORS'), false);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization', 
    'X-Requested-With', 
    'Accept', 
    'Origin'
  ]
};
```

### Frontend Configuration

Pastikan frontend mengirim request dengan benar:

```javascript
// Correct way to send requests
fetch('http://54.179.2.8:4002/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  credentials: 'include', // Important for CORS
  body: JSON.stringify({
    email: 'rajif@gmail.com',
    password: 'mypassword'
  })
});
```

## 🐛 Debugging CORS Issues

### 1. Check Server Logs

```bash
# Check server logs untuk CORS blocked origins
docker logs starhub-express | grep "CORS blocked origin"
```

### 2. Browser Developer Tools

1. Buka Developer Tools (F12)
2. Go to Network tab
3. Look for failed requests dengan status 0 atau CORS error
4. Check Response Headers untuk Access-Control-Allow-Origin

### 3. Test dengan Postman/Insomnia

Test API dengan tools seperti Postman untuk memastikan API berfungsi tanpa CORS issues.

## 📋 Checklist CORS

- [ ] ✅ Server CORS configuration updated
- [ ] ✅ ALLOWED_ORIGINS environment variable set
- [ ] ✅ Frontend domain included in allowed origins
- [ ] ✅ NODE_ENV set correctly (development/production)
- [ ] ✅ OPTIONS requests handled properly
- [ ] ✅ Credentials: true set in CORS config
- [ ] ✅ All required headers allowed
- [ ] ✅ Server logs checked for blocked origins

## 🚀 Deployment Checklist

### Before Deployment

1. **Update ALLOWED_ORIGINS** dengan production domains
2. **Set NODE_ENV=production**
3. **Test CORS** dengan production URLs
4. **Update frontend** untuk menggunakan production API URL

### After Deployment

1. **Test login** dari frontend
2. **Check server logs** untuk CORS errors
3. **Verify** Access-Control-Allow-Origin headers
4. **Test** dengan different browsers

## 🔄 Common CORS Patterns

### Pattern 1: Development
```bash
ALLOWED_ORIGINS="http://localhost:3000,http://localhost:3001"
NODE_ENV=development
```

### Pattern 2: Staging
```bash
ALLOWED_ORIGINS="http://54.179.2.8:3000,http://54.179.2.8:3001"
NODE_ENV=production
```

### Pattern 3: Production
```bash
ALLOWED_ORIGINS="https://yourdomain.com,https://www.yourdomain.com"
NODE_ENV=production
```

## 📞 Support

Jika masih ada masalah CORS:

1. Run test script: `./scripts/test-cors.sh`
2. Check server logs
3. Verify environment variables
4. Test dengan curl commands
5. Check browser developer tools

---

**Last Updated**: $(date)
**Status**: ✅ Ready for Production
