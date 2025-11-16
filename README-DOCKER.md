# Documentación Docker - Sistema de Microservicios Azulejos Romu

## Índice
1. [Introducción](#introducción)
2. [Requisitos Previos](#requisitos-previos)
3. [Arquitectura](#arquitectura)
4. [Estructura de Docker Compose](#estructura-de-docker-compose)
5. [Servicios Incluidos](#servicios-incluidos)
6. [Volúmenes y Persistencia de Datos](#volúmenes-y-persistencia-de-datos)
7. [Redes](#redes)
8. [Configuración de Base de Datos](#configuración-de-base-de-datos)
9. [Uso del Sistema](#uso-del-sistema)
10. [Comandos Útiles](#comandos-útiles)
11. [Troubleshooting](#troubleshooting)

---

## Introducción

Este sistema de microservicios para **Azulejos Romu** está completamente dockerizado para facilitar su despliegue y ejecución. No es necesario instalar manualmente ningún servidor de base de datos, servidor de aplicaciones o configurar variables de entorno complejas.

Todo el sistema se levanta con un simple comando:
```bash
docker compose up --build
```

---

## Requisitos Previos

### Software Necesario

1. **Docker Desktop** (Windows/Mac) o **Docker Engine** (Linux)
   - Windows: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Mac: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Linux: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)

2. **Docker Compose** (incluido en Docker Desktop)
   - Versión mínima: v2.0.0

### Verificar Instalación

```bash
# Verificar Docker
docker --version

# Verificar Docker Compose
docker compose version

# Verificar que Docker está ejecutándose
docker ps
```

### Recursos Recomendados

- **RAM**: Mínimo 8 GB (recomendado 16 GB)
- **CPU**: Mínimo 4 cores
- **Disco**: Mínimo 10 GB libres
- **Puertos disponibles**: 3306, 8080, 8081, 8082, 8083, 8084, 8761, 8888

---

## Arquitectura

El sistema está compuesto por los siguientes componentes:

```
┌─────────────────────────────────────────────────────────────────┐
│                         API GATEWAY                              │
│                      (Puerto 8080)                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│   Products     │  │     Orders     │  │   Logistics    │
│   Service      │  │    Service     │  │    Service     │
│  (Puerto 8081) │  │  (Puerto 8082) │  │  (Puerto 8083) │
└────────┬───────┘  └────────┬───────┘  └────────┬───────┘
         │                   │                   │
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
                     ┌───────┴────────┐
                     │                │
                     ▼                ▼
            ┌────────────────┐  ┌──────────────┐
            │  Users Service │  │    MySQL     │
            │  (Puerto 8084) │  │  (Puerto     │
            └────────┬───────┘  │    3306)     │
                     │          └──────────────┘
                     │
                     └──────────┘

┌─────────────────────────────────────────────────────────────────┐
│           SERVICIOS DE INFRAESTRUCTURA                           │
│  ┌─────────────────┐        ┌─────────────────┐                │
│  │ Eureka Discovery│        │  Config Server  │                │
│  │  (Puerto 8761)  │        │  (Puerto 8888)  │                │
│  └─────────────────┘        └─────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Estructura de Docker Compose

El archivo `docker-compose.yml` define 8 servicios principales:

### 1. MySQL Database
- **Imagen**: `mysql:8.0`
- **Puerto**: `3306`
- **Función**: Base de datos relacional compartida para todos los microservicios
- **Bases de datos**:
  - `products_db` (Productos)
  - `orders_db` (Pedidos)
  - `logistics_db` (Logística)
  - `users_db` (Usuarios)

### 2. Config Server
- **Puerto**: `8888`
- **Función**: Servidor de configuración centralizada (Spring Cloud Config)
- **Dependencias**: Ninguna

### 3. Discovery Server (Eureka)
- **Puerto**: `8761`
- **Función**: Registro y descubrimiento de servicios
- **Dependencias**: Config Server
- **Dashboard**: `http://localhost:8761`

### 4. Products Service
- **Puerto**: `8081`
- **Función**: Gestión de productos, categorías, proveedores, almacenes y stock
- **Base de datos**: `products_db`
- **Dependencias**: MySQL, Discovery Server

### 5. Orders Service
- **Puerto**: `8082`
- **Función**: Gestión de pedidos y órdenes
- **Base de datos**: `orders_db`
- **Dependencias**: MySQL, Discovery Server, Products Service

### 6. Logistics Service
- **Puerto**: `8083`
- **Función**: Gestión de logística, camiones, rutas y GPS
- **Base de datos**: `logistics_db`
- **Dependencias**: MySQL, Discovery Server

### 7. Users Service
- **Puerto**: `8084`
- **Función**: Gestión de usuarios, autenticación JWT
- **Base de datos**: `users_db`
- **Dependencias**: MySQL, Discovery Server

### 8. Gateway Service
- **Puerto**: `8080`
- **Función**: Puerta de entrada única para todos los servicios
- **Dependencias**: Discovery Server, todos los microservicios

---

## Servicios Incluidos

### Detalles por Servicio

#### MySQL Container
```yaml
Imagen: mysql:8.0
Usuario: azulejos
Contraseña: azulejos123
Root Password: rootpass123
Volumen: mysql_data (persistente)
Healthcheck: mysqladmin ping
```

#### Config Server
```yaml
Puerto: 8888
Endpoints:
  - /actuator/health
  - /{application}/{profile}
```

#### Eureka Discovery Server
```yaml
Puerto: 8761
Dashboard: http://localhost:8761
Endpoints:
  - /actuator/health
  - /eureka/apps (listado de servicios)
```

#### Products Service
```yaml
Puerto: 8081
Base de datos: products_db
Entidades: Product, Supplier, Category, Warehouse, Stock, StockMovement
Swagger UI: http://localhost:8081/swagger-ui/index.html
Health: http://localhost:8081/actuator/health
```

#### Orders Service
```yaml
Puerto: 8082
Base de datos: orders_db
Entidades: Order, OrderItem, OrderStatusHistory
Swagger UI: http://localhost:8082/swagger-ui/index.html
Health: http://localhost:8082/actuator/health
```

#### Logistics Service
```yaml
Puerto: 8083
Base de datos: logistics_db
Entidades: Truck, Driver, Route, RouteStop, GpsTracking
Swagger UI: http://localhost:8083/swagger-ui/index.html
Health: http://localhost:8083/actuator/health
Features: Optimización de rutas, tracking GPS
```

#### Users Service
```yaml
Puerto: 8084
Base de datos: users_db
Entidades: User, WarehouseAssignment, AuditLog
Swagger UI: http://localhost:8084/swagger-ui/index.html
Health: http://localhost:8084/actuator/health
Features: JWT Authentication, BCrypt encryption
```

#### Gateway Service
```yaml
Puerto: 8080
Función: Enrutamiento inteligente a microservicios
Health: http://localhost:8080/actuator/health
Rutas:
  - /products/** → products-service
  - /orders/** → orders-service
  - /logistics/** → logistics-service
  - /users/** → users-service
```

---

## Volúmenes y Persistencia de Datos

### Volumen MySQL

El volumen `mysql_data` garantiza que los datos persisten entre reinicios de contenedores:

```yaml
volumes:
  mysql_data:
    driver: local
```

**Ubicación de los datos:**
- Windows: `\\wsl$\docker-desktop-data\version-pack-data\community\docker\volumes\`
- Mac: `~/Library/Containers/com.docker.docker/Data/vms/0/`
- Linux: `/var/lib/docker/volumes/`

**Comandos relacionados:**

```bash
# Ver volúmenes
docker volume ls

# Inspeccionar volumen
docker volume inspect aos_mysql_data

# Eliminar volumen (¡CUIDADO! Se pierden todos los datos)
docker compose down -v
```

### Scripts de Inicialización

Los scripts SQL en `/docker/mysql-init/` se ejecutan automáticamente al crear el contenedor MySQL por primera vez:

- `01-init-databases.sql`: Crea las 4 bases de datos y otorga permisos

**IMPORTANTE**: Estos scripts solo se ejecutan si el volumen `mysql_data` no existe. Para forzar su ejecución:

```bash
# Eliminar volumen y recrear
docker compose down -v
docker compose up --build
```

---

## Redes

Todos los contenedores se comunican a través de una red bridge personalizada:

```yaml
networks:
  azulejos-network:
    driver: bridge
```

**Ventajas:**
- Aislamiento de red
- Resolución de nombres automática (por nombre de servicio)
- Los servicios pueden comunicarse usando nombres: `mysql`, `products-service`, etc.

**Ejemplo de comunicación interna:**
```
products-service → jdbc:mysql://mysql:3306/products_db
orders-service → http://products-service:8081/api/...
```

---

## Configuración de Base de Datos

### Conexiones desde los Microservicios

Cada microservicio se conecta a su base de datos específica:

```yaml
# Products Service
SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/products_db?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
SPRING_DATASOURCE_USERNAME: azulejos
SPRING_DATASOURCE_PASSWORD: azulejos123
```

### Parámetros de Conexión

- `createDatabaseIfNotExist=true`: Crea la BD si no existe
- `useSSL=false`: Desactiva SSL para desarrollo
- `allowPublicKeyRetrieval=true`: Permite autenticación con MySQL 8.0

### Acceso Externo a MySQL

Para conectarte desde herramientas externas (MySQL Workbench, DBeaver, etc.):

```
Host: localhost
Puerto: 3306
Usuario: azulejos
Contraseña: azulejos123
Bases de datos: products_db, orders_db, logistics_db, users_db
```

---

## Uso del Sistema

### Inicio Rápido

#### Windows (PowerShell)

```powershell
# Ejecutar script de pruebas automatizado
.\test-microservices.ps1
```

#### Linux/Mac (Bash)

```bash
# Dar permisos de ejecución
chmod +x test-microservices.sh

# Ejecutar script de pruebas
./test-microservices.sh
```

### Inicio Manual

```bash
# 1. Construir y levantar todos los servicios
docker compose up --build -d

# 2. Ver logs en tiempo real
docker compose logs -f

# 3. Verificar estado de servicios
docker compose ps

# 4. Acceder a Eureka Dashboard
# Abrir navegador: http://localhost:8761

# 5. Probar un endpoint
curl http://localhost:8081/actuator/health
```

### Detener Sistema

```bash
# Detener servicios (mantiene volúmenes)
docker compose down

# Detener servicios y eliminar volúmenes (¡Se pierden datos!)
docker compose down -v

# Detener un servicio específico
docker compose stop products-service
```

---

## Comandos Útiles

### Gestión de Contenedores

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
```

### Inspección y Debug

```bash
# Entrar en un contenedor
docker exec -it azulejos-romu-mysql bash
docker exec -it products-service bash

# Conectar a MySQL desde línea de comandos
docker exec -it azulejos-romu-mysql mysql -u azulejos -pazulejos123

# Ver uso de recursos
docker stats

# Inspeccionar red
docker network inspect aos_azulejos-network

# Ver imagen de un servicio
docker images | grep products-service
```

### Limpieza

```bash
# Limpiar contenedores detenidos
docker container prune

# Limpiar imágenes no usadas
docker image prune

# Limpiar todo (contenedores, redes, imágenes no usadas)
docker system prune

# Limpiar incluyendo volúmenes (¡CUIDADO!)
docker system prune -a --volumes
```

---

## Troubleshooting

### Problema: Contenedores no inician

**Síntomas:**
```
Error: Container exited with code 1
```

**Soluciones:**
```bash
# Ver logs del servicio problemático
docker compose logs [service-name]

# Verificar puertos en uso
# Windows
netstat -ano | findstr :8080

# Linux/Mac
lsof -i :8080

# Liberar puerto o cambiar en docker-compose.yml
```

### Problema: MySQL no acepta conexiones

**Síntomas:**
```
Communications link failure
Connection refused
```

**Soluciones:**
```bash
# Verificar que MySQL esté saludable
docker compose ps

# Ver logs de MySQL
docker compose logs mysql

# Esperar más tiempo (puede tardar hasta 30 segundos)
sleep 30

# Reiniciar MySQL
docker compose restart mysql
```

### Problema: Servicios no se registran en Eureka

**Síntomas:**
- Dashboard Eureka vacío
- Servicios no se encuentran entre sí

**Soluciones:**
```bash
# Verificar que Eureka esté funcionando
curl http://localhost:8761/actuator/health

# Revisar logs de Discovery Server
docker compose logs discovery-server

# Reiniciar servicios en orden
docker compose restart discovery-server
sleep 10
docker compose restart products-service orders-service logistics-service users-service
```

### Problema: Error al construir imágenes

**Síntomas:**
```
ERROR: failed to build
```

**Soluciones:**
```bash
# Limpiar caché de Docker
docker builder prune

# Reconstruir sin caché
docker compose build --no-cache

# Verificar espacio en disco
docker system df
```

### Problema: Volúmenes corruptos

**Síntomas:**
- Datos inconsistentes
- Errores de base de datos

**Soluciones:**
```bash
# ADVERTENCIA: Esto eliminará todos los datos

# 1. Detener y eliminar volúmenes
docker compose down -v

# 2. Verificar eliminación
docker volume ls

# 3. Recrear todo
docker compose up --build -d
```

### Problema: Puertos ya en uso

**Síntomas:**
```
Error: Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Soluciones:**

**Opción 1: Liberar el puerto**
```bash
# Windows (PowerShell como Admin)
Get-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess | Stop-Process

# Linux/Mac
sudo lsof -ti:8080 | xargs kill -9
```

**Opción 2: Cambiar puerto en docker-compose.yml**
```yaml
gateway-service:
  ports:
    - "9080:8080"  # Cambiar 8080 → 9080 externamente
```

### Problema: Rendimiento lento

**Soluciones:**
```bash
# Aumentar recursos en Docker Desktop
# Settings → Resources →
#   - CPUs: 4+
#   - Memory: 8 GB+
#   - Swap: 2 GB+

# Verificar uso de recursos
docker stats

# Limitar recursos de un servicio
# En docker-compose.yml:
services:
  products-service:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

---

## URLs Importantes

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

---

## Estructura de Archivos

```
AOS/
├── docker-compose.yml           # Configuración principal de Docker Compose
├── docker/
│   └── mysql-init/
│       └── 01-init-databases.sql # Script de inicialización de BD
├── codigo/
│   ├── config-server/
│   │   └── Dockerfile
│   ├── discovery-server/
│   │   └── Dockerfile
│   ├── products-service/
│   │   └── Dockerfile
│   ├── orders-service/
│   │   └── Dockerfile
│   ├── logistics-service/
│   │   └── Dockerfile
│   ├── users-service/
│   │   └── Dockerfile
│   └── gateway-service/
│       └── Dockerfile
├── test-microservices.ps1       # Script de pruebas para Windows
├── test-microservices.sh        # Script de pruebas para Linux/Mac
└── README-DOCKER.md            # Esta documentación
```

---

## Notas Adicionales

### Healthchecks

Todos los servicios tienen healthchecks configurados:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8081/actuator/health"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 60s
```

Esto garantiza que Docker Compose espere a que los servicios estén realmente listos antes de marcarlos como "healthy".

### Orden de Inicio

Docker Compose respeta el orden de dependencias:

1. MySQL (primero)
2. Config Server
3. Discovery Server (depende de Config)
4. Microservicios de negocio (dependen de Discovery y MySQL)
5. Gateway (depende de todos los microservicios)

### Variables de Entorno

Todas las configuraciones se pasan como variables de entorno en `docker-compose.yml`:

```yaml
environment:
  SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/products_db
  EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://discovery-server:8761/eureka/
```

Esto permite cambiar configuraciones sin modificar el código fuente.

---

## Contacto y Soporte

Para problemas o preguntas:
1. Revisar esta documentación
2. Verificar logs: `docker compose logs -f`
3. Consultar estado: `docker compose ps`
4. Revisar Eureka Dashboard: http://localhost:8761

---

**Última actualización**: 2025-11-16
**Versión**: 1.0.0
**Autor**: Sistema Azulejos Romu
