# Problemas Encontrados y Conclusiones

## Actividad 02 - Sistema Azulejos Romu

**Alumno**: Manahen  
**Fecha**: Noviembre 2025

---

## 1. Problemas Encontrados Durante el Desarrollo

### 1.1 Configuración de Eureka y Config Server

**Problema**: Inicialmente los microservicios no se registraban correctamente en Eureka.

**Causa**: 
- Orden de arranque incorrecto (Eureka debe iniciar primero)
- Tiempo insuficiente para que Eureka esté completamente operativo antes de arrancar los clientes

**Solución**:
```bash
# 1. Arrancar Eureka Server y esperar 10 segundos
cd eureka-server && mvn spring-boot:run &
sleep 10

# 2. Arrancar Config Server y esperar 5 segundos
cd config-server && mvn spring-boot:run &
sleep 5

# 3. Ahora arrancar los demás servicios
```

**Lección aprendida**: En arquitecturas de microservicios, el orden de arranque es crítico. Los servicios de infraestructura deben estar completamente operativos antes de iniciar los servicios de negocio.

---

### 1.2 Comunicación entre Microservicios

**Problema**: Los microservicios no podían comunicarse entre sí usando el DiscoveryClient.

**Causa**:
- Nombres de servicios inconsistentes (mayúsculas vs minúsculas)
- Load balancer no configurado correctamente

**Solución**:
```java
// Usar el nombre exacto registrado en Eureka (en mayúsculas)
List<ServiceInstance> instances = 
    discoveryClient.getInstances("PRODUCTS-SERVICE");

// O configurar gateway para usar minúsculas
spring.cloud.gateway.discovery.locator.lower-case-service-id=true
```

**Lección aprendida**: Mantener convenciones de nombres consistentes es fundamental. Documentar si se usa mayúsculas o minúsculas para los nombres de servicios.

---

### 1.3 Configuración de Base de Datos

**Problema**: Las bases de datos no se creaban automáticamente al iniciar los servicios.

**Causa**: Faltaba parámetro `createDatabaseIfNotExist=true` en la URL de conexión.

**Solución**:
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/products_db?createDatabaseIfNotExist=true&useSSL=false&serverTimezone=UTC
```

**Alternativa**: Crear manualmente las bases de datos:
```sql
CREATE DATABASE products_db;
CREATE DATABASE orders_db;
CREATE DATABASE logistics_db;
CREATE DATABASE users_db;
```

**Lección aprendida**: Para entornos de desarrollo, `createDatabaseIfNotExist=true` facilita el arranque rápido. Para producción, es mejor crear las bases de datos explícitamente y gestionar migraciones con herramientas como Flyway o Liquibase.

---

### 1.4 Gestión de Puertos en Instancias Múltiples

**Problema**: Al intentar arrancar la segunda instancia de un microservicio, fallaba porque el puerto ya estaba en uso.

**Causa**: Ambas instancias intentaban usar el mismo puerto definido en la configuración.

**Solución**:
```bash
# Instancia 1 usa el puerto del archivo de configuración (8081)
mvn spring-boot:run

# Instancia 2 sobrescribe el puerto vía parámetro
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8082
```

**Lección aprendida**: Para alta disponibilidad con múltiples instancias, es necesario parametrizar los puertos o usar asignación dinámica (`server.port=0`).

---

### 1.5 Configuración de OpenAPI/Swagger

**Problema**: Swagger UI no mostraba correctamente los endpoints en Spring Boot 3.x.

**Causa**: Cambios en las dependencias entre Spring Boot 2.x y 3.x.

**Solución**:
```xml
<!-- Para Spring Boot 3.x usar: -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.6.0</version>
</dependency>

<!-- NO usar la versión antigua: -->
<!-- <artifactId>springdoc-openapi-ui</artifactId> -->
```

**Lección aprendida**: Verificar siempre la compatibilidad de dependencias con la versión de Spring Boot utilizada.

---

### 1.6 Transacciones Distribuidas

**Problema**: Al crear un pedido que involucra múltiples microservicios (orders, products, logistics), si falla uno de los pasos, los anteriores ya se han ejecutado.

**Ejemplo**:
1. Orders Service crea el pedido ✅
2. Products Service reserva stock ✅
3. Logistics Service falla al crear la ruta ❌
4. **Resultado**: Pedido creado y stock reservado, pero sin ruta de entrega

**Causa**: No implementación del patrón Saga para transacciones distribuidas.

**Solución Implementada (Compensación Manual)**:
```java
@Service
public class OrderOrchestrationService {
    
    public OrderResponse createOrder(OrderRequest request) {
        Order order = null;
        boolean stockReserved = false;
        
        try {
            // 1. Crear pedido
            order = ordersService.create(request);
            
            // 2. Reservar stock
            stockReserved = productsService.reserveStock(order.getItems());
            if (!stockReserved) {
                throw new StockNotAvailableException();
            }
            
            // 3. Crear ruta de entrega (si aplica)
            if (order.getDeliveryType() == DeliveryType.HOME) {
                Route route = logisticsService.createRoute(order.getId());
                if (route == null) {
                    throw new RouteCreationException();
                }
            }
            
            return new OrderResponse(order);
            
        } catch (Exception e) {
            // COMPENSACIÓN: Deshacer cambios
            if (stockReserved) {
                productsService.releaseStock(order.getItems());
            }
            if (order != null) {
                ordersService.cancel(order.getId());
            }
            throw e;
        }
    }
}
```

**Solución Ideal (Patrón Saga - para implementación futura)**:
- Implementar patrón Saga Orquestado o Coreografiado
- Usar herramientas como Axon Framework o Eventuate
- Implementar eventos de dominio y compensation handlers

**Lección aprendida**: Las transacciones distribuidas son uno de los mayores desafíos en microservicios. Requieren patrones específicos (Saga, Event Sourcing) que añaden complejidad pero garantizan consistencia.

---

### 1.7 Optimización de Rutas

**Problema**: El algoritmo Nearest Neighbor es una heurística que no garantiza la ruta óptima.

**Ejemplo**:
- Para 5 destinos, podría generar una ruta 15-20% más larga que la óptima
- El Problema del Viajante (TSP) es NP-completo

**Solución Actual (Aceptable)**:
```java
// Algoritmo Nearest Neighbor O(n²)
// Rápido pero no óptimo
public Route optimizeRoute(List<Order> orders) {
    Point current = WAREHOUSE;
    Set<Order> unvisited = new HashSet<>(orders);
    List<RouteStop> stops = new ArrayList<>();
    
    while (!unvisited.isEmpty()) {
        Order nearest = findNearest(current, unvisited);
        stops.add(createStop(nearest));
        current = nearest.getLocation();
        unvisited.remove(nearest);
    }
    
    return new Route(stops);
}
```

**Soluciones Mejoradas (para producción)**:
1. **2-opt Algorithm**: Mejora la solución del Nearest Neighbor
2. **Simulated Annealing**: Mejor calidad de solución
3. **Google OR-Tools**: Biblioteca especializada en optimización de rutas
4. **API de Google Maps Directions**: Considera tráfico en tiempo real

**Lección aprendida**: Para sistemas en producción, considerar librerías especializadas en optimización como OR-Tools o APIs de mapas que manejan tráfico real.

---

### 1.8 Manejo de Errores y Resilencia

**Problema**: Si un microservicio cae, todo el sistema se ve afectado.

**Causa**: No implementación de patrones de resilencia (Circuit Breaker, Retry, Fallback).

**Solución Implementada**:
```java
@Service
public class ProductServiceClient {
    
    public Optional<Product> getProduct(Long id) {
        try {
            List<ServiceInstance> instances = 
                discoveryClient.getInstances("PRODUCTS-SERVICE");
            
            if (instances == null || instances.isEmpty()) {
                log.warn("No instances available for products-service");
                return Optional.empty();
            }
            
            // Intentar con la primera instancia
            ServiceInstance instance = instances.get(0);
            // ... llamar al servicio
            
        } catch (Exception e) {
            log.error("Error calling products-service", e);
            return Optional.empty();
        }
    }
}
```

**Solución Ideal (Circuit Breaker con Resilience4j)**:
```java
@CircuitBreaker(name = "products-service", fallbackMethod = "getProductFallback")
@Retry(name = "products-service", fallbackMethod = "getProductFallback")
public Product getProduct(Long id) {
    // Llamada al servicio
}

public Product getProductFallback(Long id, Exception e) {
    // Retornar valor por defecto o desde caché
    return getCachedProduct(id);
}
```

**Lección aprendida**: En producción, implementar Circuit Breaker, Retry y Fallback es esencial para construir sistemas resilientes.

---

## 2. Buenas Prácticas Aprendidas

### 2.1 Organización de Código

✅ **Estructura por capas en cada microservicio**:
```
src/main/java/com/azulejosromu/products/
├── model/          # Entidades JPA
├── repository/     # Repositorios Spring Data
├── service/        # Lógica de negocio
├── controller/     # REST Controllers
├── dto/            # Data Transfer Objects
├── config/         # Configuraciones
└── exception/      # Excepciones personalizadas
```

✅ **Separar DTOs de Entidades**: No exponer entidades JPA directamente en APIs

✅ **Usar Lombok** para reducir boilerplate code

---

### 2.2 Configuración

✅ **Centralizar configuración** en Config Server

✅ **Externalizar secretos**: No guardar passwords en código (usar variables de entorno)

✅ **Perfiles de Spring** para diferentes ambientes (dev, test, prod)

```yaml
# application-dev.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/products_db

# application-prod.yml  
spring:
  datasource:
    url: jdbc:mysql://prod-server:3306/products_db
```

---

### 2.3 API Design

✅ **Versionamiento de APIs**: Usar `/api/v1/products`

✅ **Códigos HTTP correctos**:
- 200 OK (GET exitoso)
- 201 Created (POST exitoso)
- 204 No Content (DELETE exitoso)
- 400 Bad Request (datos inválidos)
- 404 Not Found (recurso no existe)
- 500 Internal Server Error

✅ **Documentación con OpenAPI/Swagger**: Facilita testing y comprensión

---

### 2.4 Base de Datos

✅ **Una base de datos por microservicio**: Principio fundamental de microservicios

✅ **Migraciones versionadas**: Usar Flyway o Liquibase en producción

✅ **Índices en columnas frecuentemente consultadas**:
```sql
CREATE INDEX idx_product_code ON products(code);
CREATE INDEX idx_order_customer ON orders(customer_id);
CREATE INDEX idx_stock_product_warehouse ON stock(product_id, warehouse_id);
```

---

## 3. Mejoras Futuras Recomendadas

### 3.1 Corto Plazo

1. **Implementar autenticación JWT completa**
   - Actualmente simplificado
   - Añadir refresh tokens
   - Implementar roles y permisos granulares

2. **Añadir validaciones exhaustivas**
   - Bean Validation en todos los DTOs
   - Validaciones de negocio en capa de servicio

3. **Implementar caché**
   - Redis para catálogo de productos
   - Caché de sesiones de usuario

4. **Tests unitarios e integración**
   - JUnit 5 + Mockito
   - TestContainers para tests de integración

### 3.2 Medio Plazo

1. **Circuit Breaker con Resilience4j**
   - Evitar cascadas de fallos
   - Mejorar resiliencia del sistema

2. **Event-Driven Architecture**
   - Kafka o RabbitMQ para eventos
   - Desacoplar aún más los microservicios

3. **API Gateway mejorado**
   - Rate limiting
   - Request/Response transformation
   - Agregación de respuestas

4. **Logging centralizado**
   - ELK Stack (Elasticsearch, Logstash, Kibana)
   - Traces distribuidos con Zipkin/Jaeger

### 3.3 Largo Plazo

1. **Containerización con Docker**
   - Docker Compose para desarrollo
   - Kubernetes para producción

2. **CI/CD Pipeline**
   - Jenkins/GitLab CI
   - Despliegue automatizado

3. **Monitoreo y Alertas**
   - Prometheus + Grafana
   - Alertas proactivas

4. **Service Mesh**
   - Istio para gestión avanzada de tráfico
   - Seguridad entre servicios

---

## 4. Conclusiones Generales

### 4.1 Sobre Microservicios

**Ventajas observadas**:
- ✅ **Escalabilidad independiente**: Podemos escalar solo products-service si hay mucho tráfico de consultas
- ✅ **Tecnología heterogénea**: Cada servicio podría usar tecnologías diferentes
- ✅ **Equipos independientes**: Diferentes equipos pueden trabajar en diferentes servicios
- ✅ **Despliegue independiente**: Actualizar un servicio sin afectar a otros

**Desafíos encontrados**:
- ❌ **Complejidad operacional**: Gestionar 7+ servicios es más complejo que 1 monolito
- ❌ **Transacciones distribuidas**: Requiere patrones específicos (Saga)
- ❌ **Testing más complejo**: Tests de integración entre servicios
- ❌ **Latencia de red**: Comunicación HTTP añade latencia vs llamadas en memoria

### 4.2 Cuándo Usar Microservicios

**Sí usar cuando**:
- Sistema grande y complejo
- Equipos múltiples trabajando simultáneamente
- Necesidad de escalar partes específicas
- Diferentes requisitos tecnológicos por módulo

**No usar cuando**:
- Aplicación pequeña/simple
- Equipo pequeño (< 5 desarrolladores)
- Requisitos de latencia muy exigentes
- Transacciones ACID críticas

### 4.3 Lecciones Clave del Proyecto

1. **La división en microservicios no es única**: Existen múltiples formas válidas de dividir un sistema (ver arquitectura alternativa de Eduardo)

2. **El overhead de infraestructura es significativo**: Eureka, Config Server, Gateway, etc. añaden complejidad antes de escribir la primera línea de lógica de negocio

3. **La comunicación entre servicios es el desafío principal**: No es solo hacer un HTTP request, requiere manejo de errores, timeouts, circuit breakers, etc.

4. **La observabilidad es crucial**: Con servicios distribuidos, necesitas logging centralizado y distributed tracing para diagnosticar problemas

5. **Empieza simple, evoluciona cuando sea necesario**: En muchos casos, un monolito modular bien diseñado es mejor que microservicios prematuros

### 4.4 Aplicabilidad al Caso Real de Azulejos Romu

Para la empresa real Azulejos Romu con:
- 1 tienda
- 2 almacenes  
- Operación local en Plasencia

**Recomendación**: 
Un **monolito modular** sería probablemente más apropiado que microservicios completos. Sin embargo, este proyecto sirvió como excelente ejercicio académico para aprender los conceptos y desafíos de arquitecturas distribuidas.

Si la empresa crece significativamente (múltiples tiendas, operación nacional, alto volumen), entonces la migración a microservicios tendría más sentido.

---

## 5. Valoración Personal

Este proyecto me permitió:

- ✅ Comprender profundamente la arquitectura de microservicios
- ✅ Trabajar con Spring Cloud (Eureka, Config Server, Gateway)
- ✅ Implementar comunicación entre servicios
- ✅ Diseñar APIs RESTful documentadas con OpenAPI
- ✅ Manejar múltiples bases de datos
- ✅ Aprender patrones de diseño distribuido
- ✅ Entender los trade-offs entre diferentes arquitecturas

**Calificación de dificultad**: 8/10  
**Tiempo invertido**: ~40 horas  
**Satisfacción con el resultado**: 9/10

---

**Fecha de finalización**: Noviembre 15, 2025  
**Alumno**: Manahen
