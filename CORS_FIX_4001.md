# CORS Fix untuk Frontend Port 4001

## 🚨 Masalah
- **Postman berhasil** ✅ (tidak mengikuti CORS policy)
- **Browser gagal** ❌ (CORS policy memblokir request)
- **Frontend**: `http://54.179.2.8:4001`
- **Backend**: `http://54.179.2.8:4002`

## 🔧 Solusi Cepat

### 1. Restart Server dengan CORS Fix
```bash
chmod +x scripts/restart-with-cors.sh
./scripts/restart-with-cors.sh
```

### 2. Test CORS Configuration
```bash
chmod +x scripts/test-cors-4001.sh
./scripts/test-cors-4001.sh
```

### 3. Manual Test
```bash
# Test CORS preflight
curl -X OPTIONS \
  -H "Origin: http://54.179.2.8:4001" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  http://54.179.2.8:4002/api/auth/login

# Test login
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Origin: http://54.179.2.8:4001" \
  -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
  http://54.179.2.8:4002/api/auth/login
```

## ✅ Yang Sudah Diperbaiki

1. **CORS Configuration** - Port 4001 ditambahkan ke allowed origins
2. **Environment Variables** - ALLOWED_ORIGINS include port 4001
3. **Server Restart** - Script untuk restart dengan config baru
4. **Testing Tools** - Script untuk test CORS dari port 4001

## 🎯 Expected Result

Setelah restart, frontend di port 4001 seharusnya bisa:
- ✅ Login ke backend di port 4002
- ✅ Tidak ada CORS error di browser
- ✅ Request berhasil seperti di Postman

## 🔍 Debugging

Jika masih ada masalah:
1. Check container logs: `docker logs starhub-express`
2. Check CORS headers di browser developer tools
3. Verify environment variables: `docker exec starhub-express env | grep ALLOWED`
