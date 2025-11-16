# Definición de APIs REST - Microservicios Azulejos Romu

## Especificación OpenAPI v3.0

Todos los microservicios expondrán su documentación OpenAPI en `/v3/api-docs` y Swagger UI en `/swagger-ui/index.html`.

---

## 1. Products Service API

**Base URL**: `http://localhost:8081/api`  
**Instancia 2**: `http://localhost:8082/api`

### 1.1 Endpoints de Productos

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/products` | Listar productos con paginación | Todos |
| GET | `/products/{id}` | Obtener producto por ID | Todos |
| GET | `/products/code/{code}` | Buscar por código | Todos |
| POST | `/products` | Crear producto | ADMIN |
| PUT | `/products/{id}` | Actualizar producto | ADMIN |
| DELETE | `/products/{id}` | Desactivar producto | ADMIN |
| GET | `/products/category/{categoryId}` | Filtrar por categoría | Todos |

**Ejemplo Request/Response:**

```bash
# GET /products/{id}
curl http://localhost:8081/api/products/1

# Response 200 OK
{
  "id": 1,
  "code": "AZ-001",
  "name": "Azulejo Blanco Brillante 20x20",
  "description": "Azulejo cerámico blanco acabado brillante",
  "categoryId": 1,
  "categoryName": "Azulejos",
  "supplierId": 5,
  "supplierName": "Cerámicas del Sur",
  "price": 15.50,
  "dimensions": {
    "width": 20.0,
    "height": 20.0,
    "depth": 0.8
  },
  "unit": "m2",
  "active": true
}
```

```bash
# POST /products
curl -X POST http://localhost:8081/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "code": "MB-105",
    "name": "Mueble Baño Suspendido 80cm",
    "description": "Mueble suspendido con lavabo incluido",
    "categoryId": 2,
    "supplierId": 3,
    "price": 450.00,
    "width": 80.0,
    "height": 60.0,
    "depth": 45.0
  }'

# Response 201 Created
{
  "id": 125,
  "code": "MB-105",
  "name": "Mueble Baño Suspendido 80cm",
  "price": 450.00,
  ...
}
```

### 1.2 Endpoints de Stock

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/stock/product/{productId}` | Stock de producto en todas las ubicaciones | Todos |
| GET | `/stock/warehouse/{warehouseId}` | Todo el stock de un almacén | WAREHOUSE_WORKER, ADMIN |
| GET | `/stock/store` | Stock de la tienda | STORE_CLERK, ADMIN |
| PUT | `/stock/update` | Actualizar cantidad | WAREHOUSE_WORKER, ADMIN |
| POST | `/stock/reserve` | Reservar stock | Sistema |
| POST | `/stock/release` | Liberar reserva | Sistema |
| GET | `/stock/low-stock` | Productos bajo stock mínimo | ADMIN, WAREHOUSE_WORKER |

**Ejemplo:**

```bash
# GET /stock/product/1
curl http://localhost:8081/api/stock/product/1

# Response 200 OK
{
  "productId": 1,
  "productCode": "AZ-001",
  "productName": "Azulejo Blanco Brillante 20x20",
  "stockByLocation": [
    {
      "warehouseId": 1,
      "warehouseName": "Almacén Central",
      "quantity": 250,
      "reservedQuantity": 50,
      "availableQuantity": 200,
      "minStock": 100,
      "needsReplenishment": false
    },
    {
      "warehouseId": 3,
      "warehouseName": "Tienda Plasencia",
      "quantity": 35,
      "reservedQuantity": 10,
      "availableQuantity": 25,
      "minStock": 50,
      "needsReplenishment": true
    }
  ],
  "totalQuantity": 435,
  "totalAvailable": 355
}
```

### 1.3 Endpoints de Proveedores

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/suppliers` | Listar proveedores | ADMIN, WAREHOUSE_WORKER |
| GET | `/suppliers/{id}` | Detalle de proveedor | ADMIN, WAREHOUSE_WORKER |
| POST | `/suppliers` | Crear proveedor | ADMIN |
| PUT | `/suppliers/{id}` | Actualizar proveedor | ADMIN |

---

## 2. Orders Service API

**Base URL**: `http://localhost:8091/api`  
**Instancia 2**: `http://localhost:8092/api`

### 2.1 Endpoints Principales

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/orders` | Listar pedidos (filtros) | ADMIN, ACCOUNTANT |
| GET | `/orders/{id}` | Detalle de pedido | Propietario, ADMIN |
| POST | `/orders/customer` | Crear pedido cliente | CUSTOMER, STORE_CLERK |
| POST | `/orders/replenishment` | Pedido reposición | STORE_CLERK, WAREHOUSE_WORKER |
| POST | `/orders/supplier` | Pedido a proveedor | ADMIN, WAREHOUSE_WORKER |
| PUT | `/orders/{id}/status` | Cambiar estado | ADMIN, WAREHOUSE_WORKER |
| GET | `/orders/pending-delivery` | Pedidos pendientes | DRIVER, ADMIN |

**Ejemplo:**

```bash
# POST /orders/customer
curl -X POST http://localhost:8091/api/orders/customer \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 45,
    "deliveryType": "HOME",
    "deliveryAddress": "Calle Mayor 25",
    "deliveryCity": "Plasencia",
    "deliveryPostalCode": "10600",
    "items": [
      {"productId": 1, "quantity": 50},
      {"productId": 12, "quantity": 2}
    ],
    "notes": "Llamar antes de entregar"
  }'

# Response 201 Created
{
  "id": 1024,
  "orderNumber": "ORD-2025-001024",
  "orderType": "CUSTOMER",
  "status": "PENDING",
  "deliveryType": "HOME",
  "totalAmount": 1675.00,
  "items": [
    {
      "productId": 1,
      "productCode": "AZ-001",
      "productName": "Azulejo Blanco Brillante 20x20",
      "quantity": 50,
      "unitPrice": 15.50,
      "subtotal": 775.00
    },
    {
      "productId": 12,
      "productCode": "MB-105",
      "productName": "Mueble Baño Suspendido 80cm",
      "quantity": 2,
      "unitPrice": 450.00,
      "subtotal": 900.00
    }
  ],
  "createdAt": "2025-11-15T09:30:00"
}
```

```bash
# PUT /orders/1024/status
curl -X PUT http://localhost:8091/api/orders/1024/status \
  -H "Content-Type: application/json" \
  -d '{
    "newStatus": "IN_TRANSIT",
    "notes": "Salió en camión 1234-ABC"
  }'

# Response 200 OK
{
  "id": 1024,
  "status": "IN_TRANSIT",
  "statusHistory": [
    {
      "previousStatus": "PENDING",
      "newStatus": "PREPARING",
      "changedAt": "2025-11-15T10:00:00"
    },
    {
      "previousStatus": "PREPARING",
      "newStatus": "IN_TRANSIT",
      "changedAt": "2025-11-15T11:30:00",
      "notes": "Salió en camión 1234-ABC"
    }
  ]
}
```

---

## 3. Logistics Service API

**Base URL**: `http://localhost:8101/api`  
**Instancia 2**: `http://localhost:8102/api`

### 3.1 Endpoints de Camiones

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/trucks` | Listar camiones | ADMIN |
| GET | `/trucks/{id}` | Detalle de camión | ADMIN, DRIVER |
| POST | `/trucks` | Registrar camión | ADMIN |
| PUT | `/trucks/{id}` | Actualizar info | ADMIN |
| GET | `/trucks/available` | Camiones disponibles | ADMIN |
| PUT | `/trucks/{id}/location` | Actualizar GPS | DRIVER, Sistema |

### 3.2 Endpoints de Rutas

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/routes` | Listar rutas | ADMIN |
| POST | `/routes/optimize` | Crear ruta optimizada | ADMIN, Sistema |
| PUT | `/routes/{id}/start` | Iniciar ruta | DRIVER |
| PUT | `/routes/{id}/complete` | Completar ruta | DRIVER |
| GET | `/routes/driver/{driverId}` | Rutas del conductor | DRIVER, ADMIN |

**Ejemplo:**

```bash
# POST /routes/optimize
curl -X POST http://localhost:8101/api/routes/optimize \
  -H "Content-Type: application/json" \
  -d '{
    "routeDate": "2025-11-16",
    "truckId": 3,
    "driverId": 8,
    "orderIds": [1024, 1025, 1026, 1027, 1028]
  }'

# Response 201 Created
{
  "id": 156,
  "routeCode": "RUT-2025-156",
  "truckId": 3,
  "truckPlate": "1234-ABC",
  "driverId": 8,
  "driverName": "Carlos Martín",
  "routeDate": "2025-11-16",
  "status": "PLANNED",
  "totalDistanceKm": 45.3,
  "estimatedDurationMinutes": 180,
  "stops": [
    {
      "sequence": 1,
      "orderId": 1024,
      "address": "Calle Mayor 25, Plasencia",
      "latitude": 40.0292,
      "longitude": -6.0895,
      "estimatedArrival": "2025-11-16T09:00:00",
      "status": "PENDING"
    },
    {
      "sequence": 2,
      "orderId": 1026,
      "address": "Av. España 102, Plasencia",
      "estimatedArrival": "2025-11-16T09:30:00",
      "status": "PENDING"
    }
  ]
}
```

### 3.3 Endpoints de Tracking

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/tracking/trucks` | Posición de todos los camiones | ADMIN |
| GET | `/tracking/truck/{truckId}` | Tracking de un camión | ADMIN, DRIVER |
| POST | `/tracking/update` | Actualizar GPS | DRIVER, Sistema |

**Ejemplo:**

```bash
# GET /tracking/trucks
curl http://localhost:8101/api/tracking/trucks

# Response 200 OK
[
  {
    "truckId": 3,
    "licensePlate": "1234-ABC",
    "status": "IN_USE",
    "currentLocation": {
      "latitude": 40.0305,
      "longitude": -6.0910,
      "lastUpdate": "2025-11-16T09:15:30"
    },
    "activeRoute": {
      "routeId": 156,
      "currentStop": 2,
      "totalStops": 5,
      "nextStopAddress": "Av. España 102"
    },
    "driverName": "Carlos Martín"
  }
]
```

---

## 4. Users Service API

**Base URL**: `http://localhost:8111/api`  
**Instancia 2**: `http://localhost:8112/api`

### 4.1 Autenticación

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| POST | `/auth/login` | Iniciar sesión | Público |
| POST | `/auth/register` | Registrar cliente | Público |
| POST | `/auth/logout` | Cerrar sesión | Autenticado |
| GET | `/auth/verify` | Verificar token | Autenticado |

**Ejemplo:**

```bash
# POST /auth/login
curl -X POST http://localhost:8111/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "jgarcia",
    "password": "myPassword123"
  }'

# Response 200 OK
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 12,
    "username": "jgarcia",
    "email": "j.garcia@azulejosromu.com",
    "firstName": "Juan",
    "lastName": "García",
    "role": "WAREHOUSE_WORKER",
    "active": true
  }
}
```

### 4.2 Gestión de Usuarios

| Método | Endpoint | Descripción | Roles |
|--------|----------|-------------|-------|
| GET | `/users` | Listar usuarios | ADMIN |
| GET | `/users/{id}` | Detalle usuario | Usuario propio, ADMIN |
| POST | `/users` | Crear empleado | ADMIN |
| PUT | `/users/{id}` | Actualizar usuario | Usuario propio, ADMIN |

---

## 5. Gateway Service API

**Base URL**: `http://localhost:8080/api`

El Gateway redirige a los microservicios según el path:

| Path | Destino | Descripción |
|------|---------|-------------|
| `/api/products/**` | products-service | Productos y stock |
| `/api/orders/**` | orders-service | Pedidos |
| `/api/logistics/**` | logistics-service | Logística |
| `/api/users/**` | users-service | Usuarios |

### 5.1 Endpoints Compuestos (Orquestación)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/checkout` | Proceso completo de compra |
| GET | `/api/dashboard/admin` | Dashboard administrador |

**Ejemplo Endpoint Compuesto:**

```bash
# POST /api/checkout (Gateway orquesta: users, products, orders, logistics)
curl -X POST http://localhost:8080/api/checkout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_JWT" \
  -d '{
    "customerId": 45,
    "deliveryType": "HOME",
    "deliveryAddress": "Calle Mayor 25, Plasencia",
    "items": [
      {"productId": 1, "quantity": 50},
      {"productId": 12, "quantity": 2}
    ]
  }'

# Internamente el Gateway:
# 1. Valida token (users-service)
# 2. Verifica stock (products-service)
# 3. Crea pedido (orders-service)
# 4. Reserva stock (products-service)
# 5. Planifica ruta (logistics-service)

# Response 201 Created
{
  "orderId": 1024,
  "orderNumber": "ORD-2025-001024",
  "status": "PENDING",
  "totalAmount": 1675.00,
  "estimatedDelivery": "2025-11-17",
  "routeAssigned": true,
  "trackingAvailable": true
}
```

---

## 6. Códigos de Estado HTTP

| Código | Uso |
|--------|-----|
| 200 OK | Operación exitosa (GET, PUT) |
| 201 Created | Recurso creado (POST) |
| 204 No Content | Eliminación exitosa (DELETE) |
| 400 Bad Request | Datos inválidos |
| 401 Unauthorized | No autenticado |
| 403 Forbidden | Sin permisos |
| 404 Not Found | Recurso no encontrado |
| 409 Conflict | Conflicto (ej: código duplicado) |
| 500 Internal Server Error | Error del servidor |

## 7. Formato de Errores

```json
{
  "timestamp": "2025-11-15T10:30:00",
  "status": 400,
  "error": "Bad Request",
  "message": "El producto con código 'AZ-001' ya existe",
  "path": "/api/products"
}
```

---

## 8. Acceso a Swagger UI

- Products: http://localhost:8081/swagger-ui/index.html
- Products (Instance 2): http://localhost:8082/swagger-ui/index.html
- Orders: http://localhost:8091/swagger-ui/index.html
- Logistics: http://localhost:8101/swagger-ui/index.html
- Users: http://localhost:8111/swagger-ui/index.html
- Gateway: http://localhost:8080/swagger-ui/index.html
