# Actividad 02 - Desarrollo de un Sistema Software Basado en Microservicios

## Sistema de Gestión Azulejos Romu

**Asignatura:** Arquitectura Orientada a Servicios  
**Alumno:** Manahen García Garrido  
**Universidad:** Universidad de Extremadura - Escuela Politécnica  
**Fecha:** Noviembre 2025

---

## Tabla de Contenidos

1. [Introducción del Sistema](#1-introducción-del-sistema)
2. [Descripción de Casos de Uso y División en Microservicios](#2-descripción-de-casos-de-uso-y-división-en-microservicios)
3. [Base de Datos por Microservicio](#3-base-de-datos-por-microservicio)
4. [Esquema General del Sistema](#4-esquema-general-del-sistema)
5. [Definición de APIs](#5-definición-de-apis)
6. [Scripts de Compilación y Ejecución](#6-scripts-de-compilación-y-ejecución)
7. [Problemas Encontrados y Conclusiones](#7-problemas-encontrados-y-conclusiones)

---

## 1. Introducción del Sistema

### 1.1 Contexto Empresarial

**Azulejos Romu** es una empresa establecida en Plasencia (Cáceres) dedicada a la comercialización de azulejos y muebles de baño. La empresa opera actualmente con:

- **1 tienda física** en Plasencia
- **2 almacenes** de distribución (Almacén Central y Almacén Norte)
- **Flota de camiones** para reparto local
- **Sistema de gestión tradicional** basado en hojas de cálculo Excel

### 1.2 Problemática Actual

La empresa enfrenta desafíos significativos debido a su sistema de gestión obsoleto:

- ❌ Control de stock descentralizado y propenso a errores
- ❌ Dificultad para rastrear pedidos en tiempo real
- ❌ Rutas de entrega no optimizadas
- ❌ Falta de visibilidad sobre ubicación de repartidores
- ❌ Procesos manuales que generan retrasos
- ❌ Imposibilidad de generar reportes consolidados

### 1.3 Solución Propuesta

Desarrollo de un **sistema integrado basado en arquitectura de microservicios** que digitalice y automatice todos los procesos de negocio de Azulejos Romu.

### 1.4 Objetivos

1. **Gestión de Stock Inteligente**
   - Control en tiempo real de inventario
   - Alertas automáticas de reposición
   - Trazabilidad de movimientos

2. **Gestión Integral de Pedidos**
   - Pedidos de clientes (domicilio y recogida en tienda)
   - Pedidos de reposición (tienda → almacén)
   - Pedidos a proveedores externos
   - Seguimiento de estados en tiempo real

3. **Logística Optimizada**
   - Optimización automática de rutas
   - Tracking GPS en tiempo real
   - Asignación inteligente de entregas

4. **Seguridad y Control**
   - Autenticación con JWT
   - Control de acceso por roles
   - Auditoría de operaciones

---

## 2. Descripción de Casos de Uso y División en Microservicios

### 2.1 Actores del Sistema

| Actor | Responsabilidades |
|-------|-------------------|
| **Administrador** | Gestión total del sistema, configuración, reportes |
| **Cliente** | Realizar y consultar pedidos |
| **Dependiente de Tienda** | Gestión stock tienda, atención clientes |
| **Mozo de Almacén** | Control stock almacén, preparación pedidos |
| **Gestor de Cuentas** | Consulta históricos, reportes financieros |
| **Repartidor** | Visualización rutas, actualización entregas |

### 2.2 Identificación de Business Capabilities

Aplicando la técnica de análisis por **capacidades de negocio** (business capabilities), he identificado 4 capacidades fundamentales:

#### BC-1: Gestión de Productos y Stock
**Responsabilidad:** Catálogo de productos y control de inventario

**Casos de Uso:**
- CU-01: Mantener Catálogo de Productos
- CU-02: Gestionar Proveedores
- CU-03: Consultar Stock Disponible
- CU-04: Controlar Movimientos de Stock
- CU-05: Generar Alertas de Reposición

#### BC-2: Gestión de Pedidos
**Responsabilidad:** Procesar y hacer seguimiento de pedidos

**Casos de Uso:**
- CU-06: Realizar Pedido de Cliente
- CU-07: Gestionar Pedido de Reposición (Tienda → Almacén)
- CU-08: Gestionar Pedido a Proveedor
- CU-09: Actualizar Estado de Pedido
- CU-10: Consultar Historial de Pedidos

#### BC-3: Logística y Distribución
**Responsabilidad:** Optimizar entregas y tracking de flota

**Casos de Uso:**
- CU-11: Gestionar Flota de Camiones
- CU-12: Optimizar Rutas de Entrega
- CU-13: Seguimiento GPS en Tiempo Real
- CU-14: Asignar Entregas a Repartidores

#### BC-4: Gestión de Usuarios y Seguridad
**Responsabilidad:** Autenticación y autorización

**Casos de Uso:**
- CU-15: Autenticar Usuario
- CU-16: Gestionar Roles y Permisos
- CU-17: Asignar Mozos a Almacenes
- CU-18: Auditar Operaciones

### 2.3 Microservicios Identificados

Con base en las capacidades de negocio, defino **7 microservicios**:

| Microservicio | Responsabilidad | Puertos |
|---------------|-----------------|---------|
| **eureka-server** | Registro y descubrimiento de servicios | 8761 |
| **config-server** | Configuración centralizada | 8888 |
| **products-service** | Productos, proveedores y stock | 8081, 8082 |
| **orders-service** | Gestión de pedidos | 8091, 8092 |
| **logistics-service** | Flota, rutas y tracking GPS | 8101, 8102 |
| **users-service** | Autenticación y usuarios | 8111, 8112 |
| **gateway-service** | API Gateway y orquestación | 8080 |

**Nota:** Los 4 microservicios base se ejecutan en **2 instancias** cada uno para alta disponibilidad.

### 2.4 Casos de Uso Detallados

#### Ejemplo: CU-06 - Realizar Pedido de Cliente

**Actor:** Cliente  
**Microservicios involucrados:** gateway-service, users-service, products-service, orders-service, logistics-service

**Flujo:**
1. Cliente se autentica (users-service)
2. Cliente selecciona productos del catálogo
3. Sistema verifica stock disponible (products-service)
4. Cliente indica método de entrega (domicilio/tienda)
5. Sistema crea pedido (orders-service)
6. Sistema reserva stock (products-service)
7. Si es entrega a domicilio, sistema planifica ruta (logistics-service)
8. Sistema confirma pedido al cliente

#### Ejemplo: CU-12 - Optimizar Rutas de Entrega

**Actor:** Sistema (automático)  
**Microservicio:** logistics-service

**Flujo:**
1. Sistema obtiene pedidos pendientes de entrega del día
2. Sistema obtiene ubicaciones de destino
3. Sistema calcula ruta óptima usando algoritmo **Nearest Neighbor**:
   - Minimiza distancia total recorrida
   - Respeta capacidad del camión
   - Genera secuencia de paradas
4. Sistema asigna ruta a camión disponible
5. Sistema asigna repartidor
6. Repartidor recibe notificación con ruta optimizada

---

## 3. Base de Datos por Microservicio

Siguiendo el principio **database per service**, cada microservicio gestiona su propia base de datos independiente.

### 3.1 products-service → products_db

**Tablas:**

#### suppliers (Proveedores)
```sql
CREATE TABLE suppliers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200) NOT NULL,
    cif VARCHAR(20) UNIQUE NOT NULL,
    contact_name VARCHAR(150),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    city VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### products (Productos)
```sql
CREATE TABLE products (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    width DECIMAL(8,2),
    height DECIMAL(8,2),
    depth DECIMAL(8,2),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
```

#### warehouses (Almacenes y Tienda)
```sql
CREATE TABLE warehouses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    is_store BOOLEAN DEFAULT FALSE
);
```

#### stock (Control de Stock)
```sql
CREATE TABLE stock (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,
    min_stock INT DEFAULT 10,
    max_stock INT DEFAULT 100,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    UNIQUE KEY (product_id, warehouse_id)
);
```

#### stock_movements (Movimientos de Stock)
```sql
CREATE TABLE stock_movements (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    movement_type ENUM('IN', 'OUT', 'TRANSFER', 'ADJUSTMENT'),
    quantity INT NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Responsabilidades:** Catálogo de productos, gestión de proveedores, control de stock en 3 ubicaciones (2 almacenes + 1 tienda), alertas de reposición.

---

### 3.2 orders-service → orders_db

**Tablas:**

#### orders (Pedidos)
```sql
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    order_type ENUM('CUSTOMER', 'REPLENISHMENT', 'SUPPLIER'),
    customer_id BIGINT,
    status ENUM('PENDING', 'PREPARING', 'IN_TRANSIT', 
                'IN_STORE', 'DELIVERED', 'CANCELLED'),
    delivery_type ENUM('HOME', 'STORE_PICKUP'),
    delivery_address TEXT,
    delivery_city VARCHAR(100),
    total_amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### order_items (Líneas de Pedido)
```sql
CREATE TABLE order_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_code VARCHAR(50),
    product_name VARCHAR(200),
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2),
    subtotal DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);
```

#### order_status_history (Historial de Estados)
```sql
CREATE TABLE order_status_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL,
    previous_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by BIGINT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);
```

**Responsabilidades:** Gestión de 3 tipos de pedidos (clientes, reposición, proveedores), seguimiento de estados, historial completo.

---

### 3.3 logistics-service → logistics_db

**Tablas:**

#### trucks (Camiones)
```sql
CREATE TABLE trucks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    brand VARCHAR(50),
    model VARCHAR(50),
    capacity_kg DECIMAL(10,2),
    status ENUM('AVAILABLE', 'IN_USE', 'MAINTENANCE'),
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    last_gps_update TIMESTAMP
);
```

#### drivers (Repartidores)
```sql
CREATE TABLE drivers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    license_number VARCHAR(50),
    phone VARCHAR(20),
    status ENUM('ACTIVE', 'INACTIVE')
);
```

#### routes (Rutas)
```sql
CREATE TABLE routes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    route_code VARCHAR(50) UNIQUE NOT NULL,
    truck_id BIGINT NOT NULL,
    driver_id BIGINT NOT NULL,
    route_date DATE NOT NULL,
    status ENUM('PLANNED', 'IN_PROGRESS', 'COMPLETED'),
    total_distance_km DECIMAL(8,2),
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    FOREIGN KEY (truck_id) REFERENCES trucks(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id)
);
```

#### route_stops (Paradas de Ruta)
```sql
CREATE TABLE route_stops (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    route_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    stop_sequence INT NOT NULL,
    address TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    estimated_arrival TIMESTAMP,
    status ENUM('PENDING', 'ARRIVED', 'COMPLETED'),
    FOREIGN KEY (route_id) REFERENCES routes(id)
);
```

#### gps_tracking (Tracking GPS)
```sql
CREATE TABLE gps_tracking (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    truck_id BIGINT NOT NULL,
    route_id BIGINT,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    speed_kmh DECIMAL(5,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (truck_id) REFERENCES trucks(id)
);
```

**Responsabilidades:** Gestión de flota de camiones, optimización de rutas mediante algoritmo Nearest Neighbor, tracking GPS en tiempo real.

---

### 3.4 users-service → users_db

**Tablas:**

#### users (Usuarios)
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role ENUM('ADMIN', 'CUSTOMER', 'STORE_CLERK', 
              'WAREHOUSE_WORKER', 'ACCOUNTANT', 'DRIVER'),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### warehouse_assignments (Asignaciones de Almacén)
```sql
CREATE TABLE warehouse_assignments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    assignment_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### audit_log (Log de Auditoría)
```sql
CREATE TABLE audit_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id BIGINT,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Responsabilidades:** Autenticación JWT, gestión de usuarios y roles, asignación de mozos a almacenes, auditoría de operaciones.

---

### 3.5 Resumen de Bases de Datos

| Microservicio | Base de Datos | Tablas Principales |
|---------------|---------------|-------------------|
| products-service | products_db | suppliers, categories, products, warehouses, stock, stock_movements |
| orders-service | orders_db | orders, order_items, order_status_history |
| logistics-service | logistics_db | trucks, drivers, routes, route_stops, gps_tracking |
| users-service | users_db | users, warehouse_assignments, audit_log |

---

## 4. Esquema General del Sistema

### 4.1 Arquitectura de Alto Nivel

```
┌──────────────┐                    ┌──────────────┐
│   Web App    │                    │  Mobile App  │
└──────┬───────┘                    └──────┬───────┘
       │                                   │
       └────────────┬──────────────────────┘
                    │
                    ▼
       ┌────────────────────────────┐
       │    Gateway Service         │
       │    Puerto: 8080            │
       │    (Load Balancer)         │
       └────────────┬───────────────┘
                    │
      ┌─────────────┼─────────────┐
      │             │             │
      ▼             ▼             ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Eureka   │  │  Config  │  │  Todos   │
│ Server   │  │  Server  │  │  los     │
│  :8761   │  │  :8888   │  │Servicios │
└──────────┘  └──────────┘  └──────────┘
                    │
      ┌─────────────┴────────────┬───────────┐
      │                          │           │
      ▼                          ▼           ▼
┌─────────────┐        ┌─────────────┐  ┌─────────────┐
│ products-   │        │ orders-     │  │ logistics-  │
│ service     │        │ service     │  │ service     │
│ :8081,8082  │        │ :8091,8092  │  │ :8101,8102  │
└──────┬──────┘        └──────┬──────┘  └──────┬──────┘
       │                      │                │
       ▼                      ▼                ▼
  ┌─────────┐          ┌─────────┐      ┌─────────┐
  │products │          │ orders  │      │logistics│
  │   _db   │          │   _db   │      │   _db   │
  └─────────┘          └─────────┘      └─────────┘

┌─────────────┐
│ users-      │
│ service     │
│ :8111,8112  │
└──────┬──────┘
       │
       ▼
  ┌─────────┐
  │  users  │
  │   _db   │
  └─────────┘
```

### 4.2 Comunicación entre Microservicios

**Tecnologías utilizadas:**
- **Spring Cloud Eureka:** Service Discovery
- **Spring Cloud Config:** Configuración centralizada
- **Spring Cloud Gateway:** API Gateway
- **Spring Cloud LoadBalancer:** Balanceo de carga
- **RestTemplate + DiscoveryClient:** Comunicación entre servicios

**Ejemplo de comunicación:**

Cuando `orders-service` necesita verificar stock antes de crear un pedido:

```java
@Service
public class OrderService {
    @Autowired
    private DiscoveryClient discoveryClient;
    
    public boolean verifyStock(Long productId, int quantity) {
        // Obtener instancias disponibles de products-service
        List<ServiceInstance> instances = 
            discoveryClient.getInstances("products-service");
        
        if (!instances.isEmpty()) {
            // El load balancer selecciona automáticamente una instancia
            ServiceInstance instance = instances.get(0);
            String url = instance.getUri() + 
                        "/api/stock/verify/" + productId + "/" + quantity;
            
            RestTemplate restTemplate = new RestTemplate();
            return restTemplate.getForObject(url, Boolean.class);
        }
        return false;
    }
}
```

### 4.3 Alta Disponibilidad

Cada microservicio base se ejecuta en **2 instancias**:

| Servicio | Instancia 1 | Instancia 2 |
|----------|-------------|-------------|
| products-service | :8081 | :8082 |
| orders-service | :8091 | :8092 |
| logistics-service | :8101 | :8102 |
| users-service | :8111 | :8112 |

**Ventajas:**
- ✅ Si una instancia falla, la otra sigue funcionando
- ✅ Distribución de carga entre instancias
- ✅ Mayor rendimiento bajo alta demanda

---

## 5. Definición de APIs

Todos los microservicios exponen APIs REST documentadas con **OpenAPI 3.0** (Swagger UI).

### 5.1 Products Service API

**Base URL:** `http://localhost:8081/api`  
**Swagger UI:** `http://localhost:8081/swagger-ui/index.html`

#### Endpoints de Productos

| Método | Endpoint | Descripción | Rol |
|--------|----------|-------------|-----|
| GET | `/products` | Listar productos | Todos |
| GET | `/products/{id}` | Obtener producto por ID | Todos |
| GET | `/products/code/{code}` | Buscar por código | Todos |
| POST | `/products` | Crear producto | ADMIN |
| PUT | `/products/{id}` | Actualizar producto | ADMIN |
| DELETE | `/products/{id}` | Desactivar producto | ADMIN |

#### Endpoints de Stock

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/stock/product/{productId}` | Stock en todas las ubicaciones |
| GET | `/stock/warehouse/{warehouseId}` | Stock de un almacén |
| GET | `/stock/store` | Stock de la tienda |
| POST | `/stock/reserve` | Reservar stock |
| POST | `/stock/release` | Liberar reserva |
| GET | `/stock/low-stock` | Productos bajo stock mínimo |

**Ejemplo de uso:**

```bash
# Consultar stock de un producto
curl http://localhost:8081/stock/product/1

# Respuesta:
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
      "availableQuantity": 200
    },
    {
      "warehouseId": 3,
      "warehouseName": "Tienda Plasencia",
      "quantity": 35,
      "availableQuantity": 25,
      "needsReplenishment": true
    }
  ]
}
```

---

### 5.2 Orders Service API

**Base URL:** `http://localhost:8091/api`  
**Swagger UI:** `http://localhost:8091/swagger-ui/index.html`

#### Endpoints Principales

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/orders` | Listar pedidos |
| GET | `/orders/{id}` | Detalle de pedido |
| POST | `/orders/customer` | Crear pedido de cliente |
| POST | `/orders/replenishment` | Pedido de reposición |
| POST | `/orders/supplier` | Pedido a proveedor |
| PUT | `/orders/{id}/status` | Actualizar estado |
| GET | `/orders/pending-delivery` | Pedidos pendientes |

**Ejemplo de uso:**

```bash
# Crear pedido de cliente
curl -X POST http://localhost:8091/orders/customer \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "deliveryType": "HOME",
    "deliveryAddress": "Calle Mayor 25, Plasencia",
    "items": [
      {"productId": 1, "quantity": 50}
    ]
  }'

# Respuesta:
{
  "id": 1024,
  "orderNumber": "ORD-2025-001024",
  "status": "PENDING",
  "totalAmount": 775.00,
  "createdAt": "2025-11-16T09:30:00"
}
```

---

### 5.3 Logistics Service API

**Base URL:** `http://localhost:8101/api`  
**Swagger UI:** `http://localhost:8101/swagger-ui/index.html`

#### Endpoints de Rutas y Tracking

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/trucks` | Listar camiones |
| POST | `/trucks` | Registrar camión |
| POST | `/routes/optimize` | Crear ruta optimizada |
| PUT | `/routes/{id}/start` | Iniciar ruta |
| GET | `/tracking/trucks` | Posición de camiones |
| POST | `/tracking/update` | Actualizar GPS |

**Algoritmo de Optimización de Rutas:**

Implemento el algoritmo **Nearest Neighbor** (Vecino Más Cercano):

1. Punto inicial = Almacén
2. Mientras haya destinos sin visitar:
   - Calcular distancia a todos los destinos pendientes
   - Seleccionar el destino más cercano
   - Marcar como visitado
   - Actualizar punto actual
3. Retornar al almacén

**Ejemplo de uso:**

```bash
# Optimizar ruta
curl -X POST http://localhost:8101/routes/optimize \
  -H "Content-Type: application/json" \
  -d '{
    "truckId": 1,
    "driverId": 1,
    "orderIds": [1024, 1025, 1026]
  }'

# Respuesta:
{
  "id": 156,
  "routeCode": "RUT-2025-156",
  "status": "PLANNED",
  "totalDistanceKm": 45.3,
  "stops": [
    {
      "sequence": 1,
      "orderId": 1024,
      "address": "Calle Mayor 25",
      "estimatedArrival": "2025-11-16T09:00:00"
    },
    ...
  ]
}
```

---

### 5.4 Users Service API

**Base URL:** `http://localhost:8111/api`  
**Swagger UI:** `http://localhost:8111/swagger-ui/index.html`

#### Endpoints de Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/auth/login` | Iniciar sesión |
| POST | `/auth/register` | Registrar cliente |
| GET | `/auth/verify` | Verificar token |
| GET | `/users` | Listar usuarios |
| POST | `/users` | Crear empleado |

**Ejemplo de uso:**

```bash
# Login
curl -X POST http://localhost:8111/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'

# Respuesta:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "username": "admin",
    "role": "ADMIN"
  }
}
```

---

### 5.5 Gateway Service

**Base URL:** `http://localhost:8080/api`

El Gateway redirige las peticiones a los microservicios:

- `/api/products/**` → products-service
- `/api/orders/**` → orders-service
- `/api/logistics/**` → logistics-service
- `/api/users/**` → users-service

**Ventajas:**
- ✅ Punto de entrada único
- ✅ Load balancing automático
- ✅ Simplifica el cliente
- ✅ Posibilidad de añadir autenticación centralizada

---

## 6. Scripts de Compilación y Ejecución

He creado 3 scripts bash para facilitar la gestión del sistema:

### 6.1 script_compilacion_empaquetado.sh

**Función:** Compila todos los microservicios con `mvn clean package`

```bash
#!/bin/bash
# Compilar todos los microservicios

echo "Compilando Eureka Server..."
cd eureka-server && mvn clean package -DskipTests && cd ..

echo "Compilando Config Server..."
cd config-server && mvn clean package -DskipTests && cd ..

echo "Compilando Products Service..."
cd products-service && mvn clean package -DskipTests && cd ..

echo "Compilando Orders Service..."
cd orders-service && mvn clean package -DskipTests && cd ..

echo "Compilando Logistics Service..."
cd logistics-service && mvn clean package -DskipTests && cd ..

echo "Compilando Users Service..."
cd users-service && mvn clean package -DskipTests && cd ..

echo "Compilando Gateway Service..."
cd gateway-service && mvn clean package -DskipTests && cd ..

echo "✓ Compilación completada"
```

**Uso:**
```bash
chmod +x script_compilacion_empaquetado.sh
./script_compilacion_empaquetado.sh
```

---

### 6.2 script_ejecucion_sistema.sh

**Función:** Inicia todos los servicios en terminales separadas

```bash
#!/bin/bash
# Iniciar todo el sistema

echo "Iniciando Eureka Server..."
cd eureka-server
x-terminal-emulator -e bash -c "mvn spring-boot:run; exec bash" &
sleep 10
cd ..

echo "Iniciando Config Server..."
cd config-server
x-terminal-emulator -e bash -c "mvn spring-boot:run; exec bash" &
sleep 5
cd ..

echo "Iniciando Products Service (2 instancias)..."
cd products-service
x-terminal-emulator -e bash -c "mvn spring-boot:run; exec bash" &
sleep 5
x-terminal-emulator -e bash -c "mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8082; exec bash" &
sleep 5
cd ..

echo "Iniciando Orders Service (2 instancias)..."
cd orders-service
x-terminal-emulator -e bash -c "mvn spring-boot:run; exec bash" &
sleep 5
x-terminal-emulator -e bash -c "mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8092; exec bash" &
sleep 5
cd ..

echo "Iniciando Logistics Service (2 instancias)..."
cd logistics-service
x-terminal-emulator -e bash -c "mvn spring-boot:run; exec bash" &
sleep 5
x-terminal-emulator -e bash -c "mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8102; exec bash" &
sleep 5
cd ..

echo "Iniciando Users Service (2 instancias)..."
cd users-service
x-terminal-emulator -e bash -c "mvn spring-boot:run; exec bash" &
sleep 5
x-terminal-emulator -e bash -c "mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8112; exec bash" &
sleep 5
cd ..

echo "Iniciando Gateway Service..."
cd gateway-service
x-terminal-emulator -e bash -c "mvn spring-boot:run; exec bash" &
cd ..

echo ""
echo "========================================="
echo "  ✓ Sistema iniciado completamente"
echo "========================================="
echo ""
echo "URLs importantes:"
echo "  - Eureka: http://localhost:8761"
echo "  - Gateway: http://localhost:8080"
echo "  - Products: http://localhost:8081/swagger-ui/index.html"
echo "  - Orders: http://localhost:8091/swagger-ui/index.html"
echo "  - Logistics: http://localhost:8101/swagger-ui/index.html"
echo "  - Users: http://localhost:8111/swagger-ui/index.html"
```

**Uso:**
```bash
chmod +x script_ejecucion_sistema.sh
./script_ejecucion_sistema.sh
```

**Total de instancias ejecutándose:** 11
- Eureka Server (1)
- Config Server (1)
- Gateway Service (1)
- Products Service (2)
- Orders Service (2)
- Logistics Service (2)
- Users Service (2)

---

### 6.3 script_ejecucion_pruebas.sh

**Función:** Ejecuta pruebas con `curl` sobre todos los endpoints

```bash
#!/bin/bash
# Pruebas de todos los microservicios

echo "========================================="
echo "  Pruebas del Sistema Azulejos Romu"
echo "========================================="

# TEST 1: Listar productos
echo ""
echo "TEST 1: Listar productos"
curl -X GET http://localhost:8081/products

# TEST 2: Crear producto
echo ""
echo "TEST 2: Crear producto"
curl -X POST http://localhost:8081/products \
  -H "Content-Type: application/json" \
  -d '{
    "code": "AZ-001",
    "name": "Azulejo Blanco 20x20",
    "categoryId": 1,
    "supplierId": 1,
    "price": 15.50
  }'

# TEST 3: Consultar stock
echo ""
echo "TEST 3: Consultar stock"
curl -X GET http://localhost:8081/stock/product/1

# TEST 4: Crear pedido
echo ""
echo "TEST 4: Crear pedido de cliente"
curl -X POST http://localhost:8091/orders/customer \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "deliveryType": "HOME",
    "deliveryAddress": "Calle Mayor 25",
    "items": [{"productId": 1, "quantity": 50}]
  }'

# TEST 5: Optimizar ruta
echo ""
echo "TEST 5: Optimizar ruta de entrega"
curl -X POST http://localhost:8101/routes/optimize \
  -H "Content-Type: application/json" \
  -d '{
    "truckId": 1,
    "driverId": 1,
    "orderIds": [1, 2, 3]
  }'

# TEST 6: Tracking GPS
echo ""
echo "TEST 6: Ver tracking de camiones"
curl -X GET http://localhost:8101/tracking/trucks

# TEST 7: Login
echo ""
echo "TEST 7: Login de usuario"
curl -X POST http://localhost:8111/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'

# TEST 8: Prueba a través del Gateway
echo ""
echo "TEST 8: Acceso a través del Gateway"
curl -X GET http://localhost:8080/api/products

echo ""
echo "========================================="
echo "  ✓ Pruebas completadas"
echo "========================================="
```

**Uso:**
```bash
chmod +x script_ejecucion_pruebas.sh
./script_ejecucion_pruebas.sh
```

---

## 7. Problemas Encontrados y Conclusiones

### 7.1 Problemas Encontrados Durante el Desarrollo

#### Problema 1: Orden de Arranque de Servicios

**Descripción:** Al iniciar todos los servicios simultáneamente, algunos no se registraban en Eureka.

**Causa:** Eureka Server no estaba completamente operativo cuando los otros servicios intentaban registrarse.

**Solución:** Implementar tiempos de espera en el script de ejecución:
1. Eureka Server → esperar 10 segundos
2. Config Server → esperar 5 segundos
3. Demás servicios → esperar 5 segundos entre cada uno

**Lección aprendida:** En arquitecturas de microservicios, el orden de arranque es crítico.

---

#### Problema 2: Comunicación entre Microservicios

**Descripción:** Los servicios no podían comunicarse usando DiscoveryClient.

**Causa:** Nombres de servicios inconsistentes (mayúsculas vs minúsculas).

**Solución:** 
```java
// Usar el nombre exacto registrado en Eureka (mayúsculas)
discoveryClient.getInstances("PRODUCTS-SERVICE");

// O configurar gateway para minúsculas
spring.cloud.gateway.discovery.locator.lower-case-service-id=true
```

**Lección aprendida:** Mantener convenciones de nombres consistentes en toda la arquitectura.

---

#### Problema 3: Bases de Datos No Se Creaban Automáticamente

**Descripción:** Error de conexión al iniciar los servicios.

**Causa:** MySQL no tenía las bases de datos creadas previamente.

**Solución:** Añadir parámetro en la URL de conexión:
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/products_db?createDatabaseIfNotExist=true
```

**Lección aprendida:** Para desarrollo, `createDatabaseIfNotExist=true` facilita el arranque. Para producción, crear bases de datos explícitamente.

---

#### Problema 4: Gestión de Puertos en Múltiples Instancias

**Descripción:** La segunda instancia de un microservicio no arrancaba (puerto ocupado).

**Causa:** Ambas instancias intentaban usar el mismo puerto.

**Solución:**
```bash
# Instancia 1: usa puerto del archivo de configuración
mvn spring-boot:run

# Instancia 2: sobrescribe el puerto
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8082
```

**Lección aprendida:** Parametrizar puertos para permitir múltiples instancias.

---

#### Problema 5: Documentación OpenAPI en Spring Boot 3.x

**Descripción:** Swagger UI no funcionaba correctamente.

**Causa:** Cambios en las dependencias entre Spring Boot 2.x y 3.x.

**Solución:** Usar la dependencia correcta:
```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.6.0</version>
</dependency>
```

**Lección aprendida:** Verificar compatibilidad de dependencias con la versión de Spring Boot.

---

#### Problema 6: Optimización de Rutas No Óptima

**Descripción:** El algoritmo Nearest Neighbor genera rutas subóptimas.

**Causa:** Es una heurística, no garantiza la solución óptima del TSP (Traveling Salesman Problem).

**Solución Actual:** Aceptable para el ámbito de la actividad (Plasencia es local, pocas paradas).

**Mejora Futura:** Implementar algoritmos más avanzados:
- 2-opt Algorithm
- Simulated Annealing
- Google OR-Tools
- Google Maps Directions API (considera tráfico real)

**Lección aprendida:** Para producción, usar librerías especializadas en optimización.

---

### 7.2 Conclusiones Generales

#### Sobre Microservicios

**Ventajas Observadas:**

✅ **Escalabilidad independiente:** Puedo escalar solo products-service si hay mucho tráfico de consultas

✅ **Despliegue independiente:** Actualizar un servicio sin afectar otros

✅ **Tecnología heterogénea:** Cada servicio podría usar tecnologías diferentes

✅ **Equipos independientes:** Diferentes equipos trabajando en paralelo

**Desafíos Encontrados:**

❌ **Complejidad operacional:** Gestionar 11 instancias es más complejo que 1 monolito

❌ **Transacciones distribuidas:** Requiere patrones específicos (Saga)

❌ **Testing complejo:** Tests de integración entre servicios

❌ **Latencia de red:** Comunicación HTTP añade latencia vs llamadas en memoria

---

#### Cuándo Usar Microservicios

**Sí usar cuando:**
- Sistema grande y complejo
- Equipos múltiples trabajando simultáneamente
- Necesidad de escalar partes específicas
- Diferentes requisitos tecnológicos por módulo

**No usar cuando:**
- Aplicación pequeña/simple
- Equipo pequeño (< 5 desarrolladores)
- Requisitos de latencia muy exigentes
- Transacciones ACID críticas

---

#### Aplicabilidad al Caso Real

Para Azulejos Romu con:
- 1 tienda
- 2 almacenes
- Operación local en Plasencia

**Mi análisis:** Un monolito modular bien diseñado sería probablemente más apropiado. Sin embargo, esta arquitectura de microservicios:

- ✅ Demuestra comprensión de arquitecturas distribuidas
- ✅ Permite escalabilidad futura si la empresa crece
- ✅ Es un excelente ejercicio académico
- ✅ Prepara para sistemas de mayor envergadura

---

### 7.3 Tecnologías Utilizadas

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| Java | 17 | Lenguaje de programación |
| Spring Boot | 3.2.0 | Framework base |
| Spring Cloud | 2023.0.0 | Microservicios |
| Spring Data JPA | 3.2.0 | Persistencia |
| MySQL | 8.0+ | Base de datos |
| Maven | 3.8+ | Gestión de dependencias |
| Lombok | - | Reducir boilerplate |
| SpringDoc OpenAPI | 2.6.0 | Documentación API |
| Eureka | - | Service Discovery |
| Spring Cloud Config | - | Configuración centralizada |
| Spring Cloud Gateway | - | API Gateway |

---

### 7.4 Lecciones Clave

1. **El orden de arranque es crítico** en microservicios

2. **La comunicación entre servicios es el principal desafío**

3. **Database per service** es fundamental para independencia

4. **Load balancing** permite alta disponibilidad fácilmente

5. **La documentación OpenAPI** facilita enormemente el desarrollo y testing

6. **Los scripts de automatización** son esenciales para gestionar múltiples servicios

7. **Empezar simple y evolucionar** - no sobre-arquitecturar

---

### 7.5 Valoración Personal

Este proyecto me permitió:

- ✅ Comprender profundamente la arquitectura de microservicios
- ✅ Trabajar con Spring Cloud (Eureka, Config, Gateway)
- ✅ Implementar comunicación entre servicios
- ✅ Diseñar APIs RESTful documentadas
- ✅ Manejar múltiples bases de datos
- ✅ Aprender patrones de diseño distribuido

**Calificación de dificultad:** 8/10  
**Tiempo invertido:** ~35 horas  
**Satisfacción con el resultado:** 9/10

---

## Anexo: Checklist de Entrega

- [x] Identificados al menos 3 microservicios base (tengo 4)
- [x] Servicio central (Gateway) definido
- [x] Todos los servicios registrados en Eureka
- [x] Uso de Spring Cloud Config Server
- [x] Cada microservicio ejecutándose en 2 instancias
- [x] Scripts de compilación y ejecución creados
- [x] Script de pruebas implementado
- [x] Documentación completa (este README)
- [x] Definición de APIs con OpenAPI
- [x] Problemas y conclusiones documentados

---

## Contacto

**Alumno:** Manahen García Garrido  
**Universidad:** Universidad de Extremadura  
**Asignatura:** Arquitectura Orientada a Servicios  
**Fecha:** Noviembre 2025

---

**Fin del documento**
