# Orders API Documentation

## Base URL
```
/api/order
```

## Authentication
Semua endpoint memerlukan token JWT di header:
```
Authorization: Bearer <your_jwt_token>
```

## Endpoints

### 1. Create Order
**POST** `/api/order`

**Request Body:**
```json
{
  "name": "Order Name",
  "quantity": 10
}
```

**Response:**
```json
{
  "message": "Berhasil mendaftarkan order",
  "user": {
    "id": 1,
    "name": "Order Name",
    "quantity": 10
  }
}
```

### 2. Get All Orders (dengan Pagination & Filter)
**GET** `/api/order`

**Query Parameters:**
- `page` (optional): Halaman, default = 1
- `limit` (optional): Jumlah data per halaman, default = 10
- `name` (optional): Filter berdasarkan nama order (case insensitive)
- `minQuantity` (optional): Filter quantity minimum
- `maxQuantity` (optional): Filter quantity maximum

**Example:**
```
GET /api/order?page=1&limit=5&name=test&minQuantity=5&maxQuantity=20
```

**Response:**
```json
{
  "message": "Berhasil mengambil data orders",
  "data": [
    {
      "id": 1,
      "name": "Order Name",
      "quantity": 10
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 3,
    "totalCount": 25,
    "hasNextPage": true,
    "hasPrevPage": false,
    "limit": 10
  }
}
```

### 3. Get Order by ID
**GET** `/api/order/:id`

**Response:**
```json
{
  "message": "Berhasil mengambil data order",
  "data": {
    "id": 1,
    "name": "Order Name",
    "quantity": 10
  }
}
```

### 4. Get Order Statistics
**GET** `/api/order/stats`

**Response:**
```json
{
  "message": "Berhasil mengambil statistik orders",
  "data": {
    "totalOrders": 25,
    "totalQuantity": 250,
    "averageQuantity": 10.5
  }
}
```

## Error Responses

### 404 - Order Not Found
```json
{
  "message": "Order tidak ditemukan"
}
```

### 401 - Unauthorized
```json
{
  "message": "Token tidak valid"
}
```

### 500 - Server Error
```json
{
  "message": "Terjadi kesalahan saat mengambil data orders",
  "error": "Error details"
}
```

## Frontend Implementation Examples

### JavaScript/Fetch
```javascript
// Get all orders dengan pagination
const getOrders = async (page = 1, limit = 10) => {
  const response = await fetch(`/api/order?page=${page}&limit=${limit}`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.json();
};

// Get order by ID
const getOrderById = async (id) => {
  const response = await fetch(`/api/order/${id}`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.json();
};

// Get statistics
const getStats = async () => {
  const response = await fetch('/api/order/stats', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.json();
};
```

### React/Axios
```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

// Get orders with filter
const getOrders = (params) => {
  return api.get('/order', { params });
};

// Get order by ID
const getOrderById = (id) => {
  return api.get(`/order/${id}`);
};

// Get statistics
const getStats = () => {
  return api.get('/order/stats');
};
```
