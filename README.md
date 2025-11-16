# Sistema de Gestión Azulejos Romu
## Arquitectura de Microservicios

**Asignatura:** Arquitectura Orientada a Servicios
**Alumno:** Manahen García Garrido
**Universidad:** Universidad de Extremadura - Escuela Politécnica
**Fecha:** Noviembre 2025

---

## Tabla de Contenidos

1. [Introducción del Sistema](#1-introducción-del-sistema)
2. [Descripción de Casos de Uso y División en Microservicios](#2-descripción-de-casos-de-uso-y-división-en-microservicios)
3. [Arquitectura del Sistema](#3-arquitectura-del-sistema)
4. [Base de Datos por Microservicio](#4-base-de-datos-por-microservicio)
5. [Definición de APIs](#5-definición-de-apis)
6. [Instalación y Ejecución con Docker](#6-instalación-y-ejecución-con-docker)
7. [Pruebas del Sistema](#7-pruebas-del-sistema)
8. [Problemas Encontrados y Conclusiones](#8-problemas-encontrados-y-conclusiones)

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

### 2.2 Diagrama de Casos de Uso

![Casos de Uso del Sistema](casos-de-uso.png)

### 2.3 Identificación de Business Capabilities

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

### 2.4 Microservicios Identificados

Con base en las capacidades de negocio, defino **7 microservicios**:

| Microservicio | Responsabilidad | Puerto |
|---------------|-----------------|---------|
| **config-server** | Configuración centralizada | 8888 |
| **discovery-server** | Registro y descubrimiento de servicios | 8761 |
| **products-service** | Productos, proveedores y stock | 8081 |
| **orders-service** | Gestión de pedidos | 8082 |
| **logistics-service** | Flota, rutas y tracking GPS | 8083 |
| **users-service** | Autenticación y usuarios | 8084 |
| **gateway-service** | API Gateway y orquestación | 8080 |

---

## 3. Arquitectura del Sistema

### 3.1 Diagrama de Arquitectura

![Arquitectura de Microservicios](arquitectura-microservicios.png)

### 3.2 Componentes Principales

#### MySQL Database
- **Imagen**: `mysql:8.0`
- **Puerto**: `3306`
- **Función**: Base de datos relacional para todos los microservicios
- **Bases de datos**:
  - `products_db` (Productos y stock)
  - `orders_db` (Pedidos)
  - `logistics_db` (Logística y rutas)
  - `users_db` (Usuarios y autenticación)

#### Config Server
- **Puerto**: `8888`
- **Función**: Servidor de configuración centralizada (Spring Cloud Config)
- **Configuraciones**: Almacena la configuración de todos los microservicios

#### Discovery Server (Eureka)
- **Puerto**: `8761`
- **Función**: Registro y descubrimiento de servicios
- **Dashboard**: `http://localhost:8761`

#### Products Service
- **Puerto**: `8081`
- **Función**: Gestión de productos, categorías, proveedores, almacenes y stock
- **Base de datos**: `products_db`
- **Swagger UI**: `http://localhost:8081/swagger-ui/index.html`

#### Orders Service
- **Puerto**: `8082`
- **Función**: Gestión de pedidos y órdenes
- **Base de datos**: `orders_db`
- **Swagger UI**: `http://localhost:8082/swagger-ui/index.html`

#### Logistics Service
- **Puerto**: `8083`
- **Función**: Gestión de logística, camiones, rutas y GPS
- **Base de datos**: `logistics_db`
- **Swagger UI**: `http://localhost:8083/swagger-ui/index.html`
- **Features**: Optimización de rutas con algoritmo Nearest Neighbor, tracking GPS

#### Users Service
- **Puerto**: `8084`
- **Función**: Gestión de usuarios, autenticación JWT
- **Base de datos**: `users_db`
- **Swagger UI**: `http://localhost:8084/swagger-ui/index.html`
- **Features**: JWT Authentication, BCrypt encryption

#### Gateway Service
- **Puerto**: `8080`
- **Función**: Puerta de entrada única para todos los servicios
- **Rutas**:
  - `/products/**` → products-service
  - `/orders/**` → orders-service
  - `/logistics/**` → logistics-service
  - `/users/**` → users-service

### 3.3 Comunicación entre Microservicios

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

---

## 4. Base de Datos por Microservicio

Siguiendo el principio **database per service**, cada microservicio gestiona su propia base de datos independiente.

### 4.1 products-service → products_db

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

### 4.2 orders-service → orders_db

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

### 4.3 logistics-service → logistics_db

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

### 4.4 users-service → users_db

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

### 5.2 Orders Service API

**Base URL:** `http://localhost:8082/api`
**Swagger UI:** `http://localhost:8082/swagger-ui/index.html`

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

### 5.3 Logistics Service API

**Base URL:** `http://localhost:8083/api`
**Swagger UI:** `http://localhost:8083/swagger-ui/index.html`

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

### 5.4 Users Service API

**Base URL:** `http://localhost:8084/api`
**Swagger UI:** `http://localhost:8084/swagger-ui/index.html`

#### Endpoints de Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/auth/login` | Iniciar sesión |
| POST | `/auth/register` | Registrar cliente |
| GET | `/auth/verify` | Verificar token |
| GET | `/users` | Listar usuarios |
| POST | `/users` | Crear empleado |

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

## 6. Instalación y Ejecución con Docker

### 6.1 Requisitos Previos

#### Software Necesario

1. **Docker Desktop** (Windows/Mac) o **Docker Engine** (Linux)
   - Windows: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Mac: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Linux: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)

2. **Docker Compose** (incluido en Docker Desktop)
   - Versión mínima: v2.0.0

#### Verificar Instalación

```bash
# Verificar Docker
docker --version

# Verificar Docker Compose
docker compose version

# Verificar que Docker está ejecutándose
docker ps
```

#### Recursos Recomendados

- **RAM**: Mínimo 8 GB (recomendado 16 GB)
- **CPU**: Mínimo 4 cores
- **Disco**: Mínimo 10 GB libres
- **Puertos disponibles**: 3306, 8080, 8081, 8082, 8083, 8084, 8761, 8888

### 6.2 Iniciar el Sistema

```bash
# 1. Clonar el repositorio
git clone <repository-url>
cd AOS

# 2. Construir y levantar todos los servicios
docker compose up --build -d

# 3. Ver logs en tiempo real
docker compose logs -f

# 4. Verificar estado de servicios
docker compose ps
```

### 6.3 Orden de Inicio

Docker Compose respeta el orden de dependencias definido mediante healthchecks:

1. **MySQL** (primero) - Espera hasta estar saludable (≈25 segundos)
2. **Config Server** - Espera hasta estar saludable (≈13 segundos)
3. **Discovery Server** - Depende de Config Server (≈47 segundos)
4. **Microservicios de negocio**:
   - Products Service (≈47 segundos)
   - Logistics Service (≈133 segundos si hay problemas de configuración)
   - Users Service (≈133 segundos si hay problemas de configuración)
   - Orders Service (≈149 segundos si hay problemas de configuración)
5. **Gateway** - Depende de todos los microservicios

**Nota:** Los tiempos pueden variar según los recursos del sistema.

### 6.4 URLs Importantes

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Gateway | http://localhost:8080 | Punto de entrada principal |
| Eureka Dashboard | http://localhost:8761 | Ver servicios registrados |
| Products API | http://localhost:8081 | API de productos |
| Orders API | http://localhost:8082 | API de pedidos |
| Logistics API | http://localhost:8083 | API de logística |
| Users API | http://localhost:8084 | API de usuarios |
| Products Swagger | http://localhost:8081/swagger-ui/index.html | Documentación API |
| Orders Swagger | http://localhost:8082/swagger-ui/index.html | Documentación API |
| Logistics Swagger | http://localhost:8083/swagger-ui/index.html | Documentación API |
| Users Swagger | http://localhost:8084/swagger-ui/index.html | Documentación API |

### 6.5 Detener el Sistema

```bash
# Detener servicios (mantiene volúmenes)
docker compose down

# Detener servicios y eliminar volúmenes (¡Se pierden datos!)
docker compose down -v

# Detener un servicio específico
docker compose stop products-service
```

### 6.6 Comandos Útiles

```bash
# Ver todos los contenedores
docker compose ps

# Ver logs de todos los servicios
docker compose logs

# Ver logs de un servicio específico
docker compose logs products-service

# Seguir logs en tiempo real
docker compose logs -f products-service

# Reiniciar un servicio
docker compose restart products-service

# Reconstruir un servicio específico
docker compose up --build -d products-service

# Entrar en un contenedor
docker exec -it azulejos-romu-mysql bash
docker exec -it products-service bash

# Conectar a MySQL desde línea de comandos
docker exec -it azulejos-romu-mysql mysql -u azulejos -pazulejos123

# Ver uso de recursos
docker stats
```

---

## 7. Pruebas del Sistema

### 7.1 Introducción a las Pruebas

El sistema incluye un conjunto completo de pruebas que demuestran el funcionamiento de todos los microservicios y sus interacciones. Las pruebas cubren:

- ✅ Gestión de productos y stock
- ✅ Creación y seguimiento de pedidos
- ✅ Optimización de rutas de entrega
- ✅ Tracking GPS de camiones
- ✅ Autenticación de usuarios
- ✅ Comunicación a través del API Gateway

### 7.2 Flujo de Pedido Completo

![Flujo de Pedido de Cliente](flujo-pedido-cliente.png)

El diagrama muestra el flujo completo de un pedido de cliente desde su creación hasta la entrega:

1. **Cliente realiza pedido** → Orders Service
2. **Verificación de stock** → Products Service
3. **Reserva de stock** → Products Service
4. **Creación de ruta optimizada** → Logistics Service
5. **Asignación de camión y conductor** → Logistics Service
6. **Seguimiento GPS** → Tracking en tiempo real
7. **Actualización de estado** → Notificación al cliente

### 7.3 Scripts de Pruebas Disponibles

#### Windows (PowerShell)

El script `test-microservices.ps1` automatiza todas las pruebas:

```powershell
# Ejecutar todas las pruebas
.\test-microservices.ps1
```

#### Linux/Mac (Bash)

El script `test-microservices.sh` automatiza todas las pruebas:

```bash
# Dar permisos de ejecución
chmod +x test-microservices.sh

# Ejecutar todas las pruebas
./test-microservices.sh
```

### 7.4 Pruebas Incluidas

#### TEST 1: Verificar Estado de Servicios

**Objetivo:** Comprobar que todos los servicios están en funcionamiento.

```bash
# Verificar Eureka Dashboard
curl http://localhost:8761/actuator/health

# Verificar Products Service
curl http://localhost:8081/actuator/health

# Verificar Orders Service
curl http://localhost:8082/actuator/health

# Verificar Logistics Service
curl http://localhost:8083/actuator/health

# Verificar Users Service
curl http://localhost:8084/actuator/health
```

**Resultado esperado:** Todos los servicios responden con `{"status":"UP"}`

#### TEST 2: Listar Productos

**Objetivo:** Verificar que el servicio de productos puede listar el catálogo.

```bash
curl -X GET http://localhost:8081/products
```

**Resultado esperado:** Lista de productos con sus detalles (código, nombre, precio, categoría, proveedor).

#### TEST 3: Crear Producto

**Objetivo:** Verificar que se pueden crear nuevos productos en el catálogo.

```bash
curl -X POST http://localhost:8081/products \
  -H "Content-Type: application/json" \
  -d '{
    "code": "AZ-001",
    "name": "Azulejo Blanco Brillante 20x20",
    "description": "Azulejo blanco para baño y cocina",
    "categoryId": 1,
    "supplierId": 1,
    "price": 15.50,
    "width": 20.0,
    "height": 20.0
  }'
```

**Resultado esperado:** Producto creado con ID asignado automáticamente.

#### TEST 4: Consultar Stock

**Objetivo:** Verificar el control de inventario en múltiples ubicaciones.

```bash
curl -X GET http://localhost:8081/stock/product/1
```

**Resultado esperado:** Stock del producto en todos los almacenes:
- Almacén Central: cantidad disponible, cantidad reservada
- Almacén Norte: cantidad disponible, cantidad reservada
- Tienda Plasencia: cantidad disponible, alertas de reposición

#### TEST 5: Crear Pedido de Cliente

**Objetivo:** Verificar el flujo completo de creación de un pedido.

```bash
curl -X POST http://localhost:8082/orders/customer \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "deliveryType": "HOME",
    "deliveryAddress": "Calle Mayor 25, Plasencia",
    "deliveryCity": "Plasencia",
    "items": [
      {
        "productId": 1,
        "quantity": 50
      }
    ]
  }'
```

**Resultado esperado:**
1. Pedido creado con número único (ORD-2025-XXXXX)
2. Estado inicial: PENDING
3. Stock reservado automáticamente
4. Total calculado basado en precio × cantidad

**Interacciones entre servicios:**
- Orders Service → Products Service (verificar disponibilidad)
- Orders Service → Products Service (reservar stock)

#### TEST 6: Optimizar Ruta de Entrega

**Objetivo:** Verificar el algoritmo de optimización de rutas.

```bash
curl -X POST http://localhost:8083/routes/optimize \
  -H "Content-Type: application/json" \
  -d '{
    "truckId": 1,
    "driverId": 1,
    "orderIds": [1, 2, 3, 4, 5]
  }'
```

**Resultado esperado:**
1. Ruta optimizada con código único (RUT-2025-XXXXX)
2. Secuencia de paradas calculada con algoritmo Nearest Neighbor
3. Distancia total estimada
4. Tiempos estimados de llegada a cada parada
5. Camión asignado con su capacidad
6. Conductor asignado

**Algoritmo de optimización:**
- Punto inicial: Almacén Central
- Para cada parada: seleccionar destino más cercano no visitado
- Calcular distancia euclidiana entre coordenadas
- Generar secuencia óptima de entrega

#### TEST 7: Tracking GPS de Camiones

**Objetivo:** Verificar el seguimiento en tiempo real de la flota.

```bash
curl -X GET http://localhost:8083/tracking/trucks
```

**Resultado esperado:** Lista de camiones con:
- Ubicación actual (latitud, longitud)
- Estado (DISPONIBLE, EN_RUTA, MANTENIMIENTO)
- Velocidad actual
- Última actualización GPS
- Ruta asignada (si aplica)

#### TEST 8: Actualizar Ubicación GPS

**Objetivo:** Simular actualización de posición de un camión.

```bash
curl -X POST http://localhost:8083/tracking/update \
  -H "Content-Type: application/json" \
  -d '{
    "truckId": 1,
    "latitude": 40.0381,
    "longitude": -6.0893,
    "speedKmh": 45.5
  }'
```

**Resultado esperado:** Posición actualizada y registrada en historial de tracking.

#### TEST 9: Login de Usuario

**Objetivo:** Verificar autenticación JWT.

```bash
curl -X POST http://localhost:8084/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**Resultado esperado:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "username": "admin",
    "role": "ADMIN",
    "firstName": "Administrador",
    "lastName": "Sistema"
  }
}
```

#### TEST 10: Acceso a través del Gateway

**Objetivo:** Verificar que el API Gateway enruta correctamente las peticiones.

```bash
# Acceder a productos a través del gateway
curl -X GET http://localhost:8080/api/products

# Acceder a pedidos a través del gateway
curl -X GET http://localhost:8080/api/orders

# Acceder a logística a través del gateway
curl -X GET http://localhost:8080/api/logistics/trucks

# Acceder a usuarios a través del gateway
curl -X GET http://localhost:8080/api/users
```

**Resultado esperado:** El gateway redirige automáticamente cada petición al microservicio correspondiente, utilizando el balanceo de carga de Eureka.

### 7.5 Ejecutar Pruebas Manuales

Si prefieres ejecutar las pruebas manualmente:

```bash
# 1. Asegurarse de que todos los servicios están corriendo
docker compose ps

# 2. Verificar Eureka Dashboard
# Abrir en navegador: http://localhost:8761
# Verificar que todos los servicios están registrados

# 3. Ejecutar pruebas desde Swagger UI
# Products: http://localhost:8081/swagger-ui/index.html
# Orders: http://localhost:8082/swagger-ui/index.html
# Logistics: http://localhost:8083/swagger-ui/index.html
# Users: http://localhost:8084/swagger-ui/index.html

# 4. Probar endpoints con curl (ver ejemplos arriba)
```

### 7.6 Interpretar Resultados

#### Resultados Exitosos

✅ **Código HTTP 200/201:** Operación exitosa
✅ **Servicios registrados en Eureka:** Todos los microservicios visibles
✅ **Stock actualizado correctamente:** Cantidad disponible y reservada reflejan las operaciones
✅ **Rutas optimizadas:** Distancia total minimizada con secuencia lógica
✅ **JWT válido:** Token generado y con formato correcto

#### Posibles Errores

❌ **Error 500:** Problema interno del servicio (revisar logs)
❌ **Error 404:** Recurso no encontrado (verificar IDs)
❌ **Error 503:** Servicio no disponible (verificar que está registrado en Eureka)
❌ **Connection refused:** Servicio no está corriendo (verificar docker compose ps)

### 7.7 Logs y Debugging

Para investigar problemas durante las pruebas:

```bash
# Ver logs de un servicio específico
docker compose logs -f products-service

# Ver últimas 100 líneas de logs
docker compose logs --tail=100 products-service

# Ver logs de todos los servicios
docker compose logs -f

# Buscar errores en los logs
docker compose logs products-service | grep ERROR
```

---

## 8. Problemas Encontrados y Conclusiones

### 8.1 Problemas Encontrados Durante el Desarrollo

#### Problema 1: Puertos Incorrectos en Config Server

**Descripción:** Los servicios logistics, users y orders no arrancaban correctamente y fallaban los healthchecks.

**Causa:** Los puertos configurados en el config-server no coincidían con los esperados por docker-compose:
- logistics-service: configurado en 8101, esperado 8083
- users-service: configurado en 8111, esperado 8084
- orders-service: configurado en 8091, esperado 8082

**Solución:** Corregir los archivos de configuración en:
- `codigo/config-server/src/main/resources/configurations/logistics-service.yml`
- `codigo/config-server/src/main/resources/configurations/users-service.yml`
- `codigo/config-server/src/main/resources/configurations/orders-service.yml`

**Lección aprendida:** Es crítico mantener consistencia entre la configuración centralizada y las definiciones de docker-compose.

#### Problema 2: Orden de Arranque de Servicios

**Descripción:** Al iniciar todos los servicios simultáneamente, algunos no se registraban en Eureka.

**Causa:** Eureka Server no estaba completamente operativo cuando los otros servicios intentaban registrarse.

**Solución:** Implementar healthchecks en docker-compose.yml con `depends_on` y `condition: service_healthy`:
```yaml
products-service:
  depends_on:
    mysql:
      condition: service_healthy
    discovery-server:
      condition: service_healthy
```

**Lección aprendida:** En arquitecturas de microservicios con Docker, los healthchecks son esenciales.

#### Problema 3: Comunicación entre Microservicios

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

#### Problema 4: Bases de Datos No Se Creaban Automáticamente

**Descripción:** Error de conexión al iniciar los servicios.

**Causa:** MySQL no tenía las bases de datos creadas previamente.

**Solución:** Añadir parámetro en la URL de conexión:
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/products_db?createDatabaseIfNotExist=true
```

**Lección aprendida:** Para desarrollo, `createDatabaseIfNotExist=true` facilita el arranque. Para producción, crear bases de datos explícitamente.

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

### 8.2 Conclusiones Generales

#### Sobre Microservicios

**Ventajas Observadas:**

✅ **Escalabilidad independiente:** Puedo escalar solo products-service si hay mucho tráfico de consultas

✅ **Despliegue independiente:** Actualizar un servicio sin afectar otros

✅ **Tecnología heterogénea:** Cada servicio podría usar tecnologías diferentes

✅ **Equipos independientes:** Diferentes equipos trabajando en paralelo

✅ **Resiliencia:** Si un servicio falla, los demás pueden seguir funcionando

**Desafíos Encontrados:**

❌ **Complejidad operacional:** Gestionar 7 servicios es más complejo que 1 monolito

❌ **Transacciones distribuidas:** Requiere patrones específicos (Saga)

❌ **Testing complejo:** Tests de integración entre servicios

❌ **Latencia de red:** Comunicación HTTP añade latencia vs llamadas en memoria

❌ **Debugging distribuido:** Seguir una petición a través de múltiples servicios

#### Cuándo Usar Microservicios

**Sí usar cuando:**
- Sistema grande y complejo
- Equipos múltiples trabajando simultáneamente
- Necesidad de escalar partes específicas
- Diferentes requisitos tecnológicos por módulo
- Alta disponibilidad crítica

**No usar cuando:**
- Aplicación pequeña/simple
- Equipo pequeño (< 5 desarrolladores)
- Requisitos de latencia muy exigentes
- Transacciones ACID críticas
- Presupuesto limitado para infraestructura

#### Aplicabilidad al Caso Real

Para Azulejos Romu con:
- 1 tienda
- 2 almacenes
- Operación local en Plasencia

**Mi análisis:** Un monolito modular bien diseñado sería probablemente más apropiado para el tamaño actual. Sin embargo, esta arquitectura de microservicios:

- ✅ Demuestra comprensión de arquitecturas distribuidas
- ✅ Permite escalabilidad futura si la empresa crece
- ✅ Es un excelente ejercicio académico
- ✅ Prepara para sistemas de mayor envergadura
- ✅ Facilita la incorporación de nuevas funcionalidades

### 8.3 Tecnologías Utilizadas

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| Java | 21 | Lenguaje de programación |
| Spring Boot | 3.5.7 | Framework base |
| Spring Cloud | 2023.0.0 | Microservicios |
| Spring Data JPA | 3.2.0 | Persistencia |
| MySQL | 8.0 | Base de datos |
| Maven | 3.8+ | Gestión de dependencias |
| Lombok | - | Reducir boilerplate |
| SpringDoc OpenAPI | 2.6.0 | Documentación API |
| Eureka | - | Service Discovery |
| Spring Cloud Config | - | Configuración centralizada |
| Spring Cloud Gateway | - | API Gateway |
| Docker | 24.0+ | Contenedorización |
| Docker Compose | 2.0+ | Orquestación de contenedores |

### 8.4 Lecciones Clave

1. **Los healthchecks son críticos** en entornos Docker para garantizar el orden de arranque

2. **La consistencia de configuración** entre Config Server y docker-compose es fundamental

3. **Database per service** es fundamental para independencia pero aumenta complejidad

4. **Load balancing** con Eureka permite alta disponibilidad fácilmente

5. **La documentación OpenAPI** facilita enormemente el desarrollo y testing

6. **Docker Compose** simplifica drásticamente el despliegue de microservicios

7. **Empezar simple y evolucionar** - no sobre-arquitecturar desde el principio

8. **Los logs son esenciales** para debugging en sistemas distribuidos

### 8.5 Valoración Personal

Este proyecto me permitió:

- ✅ Comprender profundamente la arquitectura de microservicios
- ✅ Trabajar con Spring Cloud (Eureka, Config, Gateway)
- ✅ Implementar comunicación entre servicios
- ✅ Diseñar APIs RESTful documentadas
- ✅ Manejar múltiples bases de datos
- ✅ Aprender patrones de diseño distribuido
- ✅ Dominar Docker y Docker Compose
- ✅ Implementar healthchecks y dependency management

**Calificación de dificultad:** 8/10
**Tiempo invertido:** ~40 horas
**Satisfacción con el resultado:** 9/10

---

## Anexo: Checklist de Entrega

- [x] Identificados al menos 3 microservicios base (tengo 4)
- [x] Servicio central (Gateway) definido
- [x] Todos los servicios registrados en Eureka
- [x] Uso de Spring Cloud Config Server
- [x] Sistema completamente dockerizado
- [x] Scripts de pruebas automatizados (PowerShell y Bash)
- [x] Documentación completa (este README)
- [x] Definición de APIs con OpenAPI
- [x] Healthchecks configurados
- [x] Problemas y conclusiones documentados
- [x] Diagramas de arquitectura y casos de uso

---

## Contacto

**Alumno:** Manahen García Garrido
**Universidad:** Universidad de Extremadura
**Asignatura:** Arquitectura Orientada a Servicios
**Fecha:** Noviembre 2025

---

**Fin del documento**
