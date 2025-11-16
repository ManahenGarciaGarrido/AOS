# Guía de Implementación Completa - Azulejos Romu Microservices

## IMPORTANTE: Sigue estos pasos en orden

Esta guía te llevará paso a paso para implementar el sistema completo de microservicios de Azulejos Romu.

---

## Fase 1: Servicios de Infraestructura

### 1.1 Crear Eureka Server

**Paso 1**: Ir a https://start.spring.io/

**Configuración**:
- Project: Maven
- Language: Java
- Spring Boot: 3.2.0
- Group: com.azulejosromu
- Artifact: eureka-server
- Name: eureka-server
- Packaging: Jar
- Java: 17

**Dependencias**:
- Eureka Server

**Paso 2**: Descargar, descomprimir e importar en tu IDE

**Paso 3**: Agregar `@EnableEurekaServer` a la clase principal
 
**Paso 4**: Crear `src/main/resources/application.yml`:
```yaml
server:
  port: 8761

spring:
  application:
    name: eureka-server

eureka:
  instance:
    hostname: localhost
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/
```

**Paso 5**: Ejecutar con `mvn spring-boot:run`

**Verificar**: Abrir http://localhost:8761

---

### 1.2 Crear Config Server

**Paso 1**: Spring Initializr

**Configuración**:
- Artifact: config-server
- Dependencias: Config Server

**Paso 2**: Agregar `@EnableConfigServer` a la clase principal

**Paso 3**: Crear `src/main/resources/application.yml`:
```yaml
server:
  port: 8888

spring:
  application:
    name: config-server
  cloud:
    config:
      server:
        native:
          search-locations: classpath:/configurations
  profiles:
    active: native
```

**Paso 4**: Crear archivos de configuración:

Crear directorio: `src/main/resources/configurations/`

**Archivo: `configurations/application.yml`** (configuración compartida):
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
    fetch-registry: true
    register-with-eureka: true
  instance:
    prefer-ip-address: true

spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
```

**Archivo: `configurations/products-service.yml`**:
```yaml
server:
  port: 8081

spring:
  application:
    name: products-service
  datasource:
    url: jdbc:mysql://localhost:3306/products_db?createDatabaseIfNotExist=true
    username: root
    password: root

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
```

**Archivo: `configurations/orders-service.yml`**:
```yaml
server:
  port: 8091

spring:
  application:
    name: orders-service
  datasource:
    url: jdbc:mysql://localhost:3306/orders_db?createDatabaseIfNotExist=true
    username: root
    password: root

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
```

**Archivo: `configurations/logistics-service.yml`**:
```yaml
server:
  port: 8101

spring:
  application:
    name: logistics-service
  datasource:
    url: jdbc:mysql://localhost:3306/logistics_db?createDatabaseIfNotExist=true
    username: root
    password: root

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
```

**Archivo: `configurations/users-service.yml`**:
```yaml
server:
  port: 8111

spring:
  application:
    name: users-service
  datasource:
    url: jdbc:mysql://localhost:3306/users_db?createDatabaseIfNotExist=true
    username: root
    password: root

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
```

**Archivo: `configurations/gateway-service.yml`**:
```yaml
server:
  port: 8080

spring:
  application:
    name: gateway-service
  cloud:
    gateway:
      discovery:
        locator:
          enabled: true
          lower-case-service-id: true
      routes:
        - id: products-service
          uri: lb://products-service
          predicates:
            - Path=/api/products/**
          filters:
            - StripPrefix=1

        - id: orders-service
          uri: lb://orders-service
          predicates:
            - Path=/api/orders/**
          filters:
            - StripPrefix=1

        - id: logistics-service
          uri: lb://logistics-service
          predicates:
            - Path=/api/logistics/**
          filters:
            - StripPrefix=1

        - id: users-service
          uri: lb://users-service
          predicates:
            - Path=/api/users/**
          filters:
            - StripPrefix=1
```

---

## Fase 2: Microservicio Products

### 2.1 Crear Proyecto

**Spring Initializr**:
- Artifact: products-service
- Dependencias:
  - Spring Web
  - Spring Data JPA
  - MySQL Driver
  - Eureka Discovery Client
  - Config Client
  - Spring Boot Actuator
  - Lombok
  - Validation

**Agregar dependencia OpenAPI** al `pom.xml`:
```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.6.0</version>
</dependency>
```

### 2.2 Configuración Bootstrap

**Crear `src/main/resources/bootstrap.yml`**:
```yaml
spring:
  application:
    name: products-service
  config:
    import: optional:configserver:http://localhost:8888
```

### 2.3 Clase Principal

```java
package com.azulejosromu.products;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class ProductsServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(ProductsServiceApplication.java, args);
    }
}
```

### 2.4 Entidades (Ejemplo: Product)

```java
package com.azulejosromu.products.model;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "products")
@Data
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true, nullable = false, length = 50)
    private String code;
    
    @Column(nullable = false, length = 200)
    private String name;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @Column(name = "category_id", nullable = false)
    private Long categoryId;
    
    @Column(name = "supplier_id", nullable = false)
    private Long supplierId;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
    
    private BigDecimal width;
    private BigDecimal height;
    private BigDecimal depth;
    private BigDecimal weight;
    
    @Column(length = 20)
    private String unit = "unidad";
    
    private Boolean active = true;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();
}
```

**Crear también**: Supplier, Category, Warehouse, Stock, StockMovement (similar estructura)

### 2.5 Repository (Ejemplo)

```java
package com.azulejosromu.products.repository;

import com.azulejosromu.products.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ProductRepository extends JpaRepository<Product, Long> {
    Optional<Product> findByCode(String code);
    List<Product> findByCategoryId(Long categoryId);
    List<Product> findByActiveTrue();
}
```

### 2.6 Service (Ejemplo)

```java
package com.azulejosromu.products.service;

import com.azulejosromu.products.model.Product;
import com.azulejosromu.products.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProductService {
    
    @Autowired
    private ProductRepository productRepository;
    
    public List<Product> findAll() {
        return productRepository.findAll();
    }
    
    public Optional<Product> findById(Long id) {
        return productRepository.findById(id);
    }
    
    public Optional<Product> findByCode(String code) {
        return productRepository.findByCode(code);
    }
    
    @Transactional
    public Product save(Product product) {
        product.setUpdatedAt(LocalDateTime.now());
        return productRepository.save(product);
    }
    
    @Transactional
    public void deleteById(Long id) {
        Product product = findById(id)
            .orElseThrow(() -> new RuntimeException("Product not found"));
        product.setActive(false);
        save(product);
    }
}
```

### 2.7 Controller (Ejemplo)

```java
package com.azulejosromu.products.controller;

import com.azulejosromu.products.model.Product;
import com.azulejosromu.products.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/products")
public class ProductController {
    
    @Autowired
    private ProductService productService;
    
    @GetMapping
    public List<Product> getAll() {
        return productService.findAll();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Product> getById(@PathVariable Long id) {
        return productService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/code/{code}")
    public ResponseEntity<Product> getByCode(@PathVariable String code) {
        return productService.findByCode(code)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public ResponseEntity<Product> create(@RequestBody Product product) {
        Product saved = productService.save(product);
        return ResponseEntity.status(201).body(saved);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Product> update(@PathVariable Long id, @RequestBody Product product) {
        if (!productService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        product.setId(id);
        Product updated = productService.save(product);
        return ResponseEntity.ok(updated);
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        productService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
```

**IMPORTANTE**: Crear controllers similares para:
- SupplierController
- StockController

---

## Fase 3: Microservicio Orders

Seguir misma estructura que products-service:

### Entidades a crear:
- Order
- OrderItem  
- OrderStatusHistory

### Controllers:
- OrderController (endpoints para crear pedidos de cliente, reposición, proveedor)

### Comunicación con otros servicios:

```java
@Service
public class OrderService {
    
    @Autowired
    private DiscoveryClient discoveryClient;
    
    // Verificar stock llamando a products-service
    public boolean verifyStock(Long productId, int quantity) {
        List<ServiceInstance> instances = 
            discoveryClient.getInstances("products-service");
        
        if (instances != null && !instances.isEmpty()) {
            ServiceInstance instance = instances.get(0);
            URI uri = instance.getUri();
            
            String url = uri + "/api/stock/verify/" + productId + "/" + quantity;
            RestTemplate restTemplate = new RestTemplate();
            
            return restTemplate.getForObject(url, Boolean.class);
        }
        return false;
    }
}
```

---

## Fase 4: Microservicio Logistics

### Entidades:
- Truck
- Driver
- Route
- RouteStop
- GpsTracking

### Lógica clave - Optimización de rutas:

```java
@Service
public class RouteOptimizationService {
    
    public Route optimizeRoute(List<Long> orderIds, Long truckId, Long driverId) {
        // Algoritmo Nearest Neighbor
        List<Order> orders = getOrders(orderIds);
        List<RouteStop> optimizedStops = new ArrayList<>();
        
        Point currentPoint = WAREHOUSE_LOCATION;
        Set<Order> unvisited = new HashSet<>(orders);
        int sequence = 1;
        
        while (!unvisited.isEmpty()) {
            Order nearest = findNearest(currentPoint, unvisited);
            
            RouteStop stop = new RouteStop();
            stop.setOrderId(nearest.getId());
            stop.setStopSequence(sequence++);
            stop.setLatitude(nearest.getDeliveryLatitude());
            stop.setLongitude(nearest.getDeliveryLongitude());
            optimizedStops.add(stop);
            
            currentPoint = new Point(nearest.getDeliveryLatitude(), nearest.getDeliveryLongitude());
            unvisited.remove(nearest);
        }
        
        Route route = new Route();
        route.setTruckId(truckId);
        route.setDriverId(driverId);
        route.setStops(optimizedStops);
        route.setTotalDistanceKm(calculateTotalDistance(optimizedStops));
        
        return routeRepository.save(route);
    }
    
    private Order findNearest(Point from, Set<Order> orders) {
        return orders.stream()
            .min((o1, o2) -> Double.compare(
                distance(from, new Point(o1.getDeliveryLatitude(), o1.getDeliveryLongitude())),
                distance(from, new Point(o2.getDeliveryLatitude(), o2.getDeliveryLongitude()))
            ))
            .orElse(null);
    }
    
    private double distance(Point p1, Point p2) {
        // Fórmula de Haversine
        double lat1 = Math.toRadians(p1.lat);
        double lon1 = Math.toRadians(p1.lon);
        double lat2 = Math.toRadians(p2.lat);
        double lon2 = Math.toRadians(p2.lon);
        
        double dlon = lon2 - lon1;
        double dlat = lat2 - lat1;
        
        double a = Math.pow(Math.sin(dlat / 2), 2) + 
                   Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(dlon / 2), 2);
        double c = 2 * Math.asin(Math.sqrt(a));
        
        return 6371 * c; // Radio de la Tierra en km
    }
}
```

---

## Fase 5: Microservicio Users

### Entidades:
- User
- WarehouseAssignment
- AuditLog

### Seguridad JWT:

```java
@Service
public class JwtService {
    
    private String secret = "AzulejosRomuSecretKey2025";
    private long expiration = 3600000; // 1 hora
    
    public String generateToken(User user) {
        return Jwts.builder()
            .setSubject(user.getUsername())
            .claim("role", user.getRole())
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(SignatureAlgorithm.HS512, secret)
            .compact();
    }
    
    public boolean validateToken(String token) {
        try {
            Jwts.parser().setSigningKey(secret).parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    public String getUsernameFromToken(String token) {
        return Jwts.parser()
            .setSigningKey(secret)
            .parseClaimsJws(token)
            .getBody()
            .getSubject();
    }
}
```

---

## Fase 6: Gateway Service

**Spring Initializr**:
- Artifact: gateway-service
- Dependencias:
  - Gateway
  - Eureka Discovery Client
  - Config Client

**Clase Principal**:
```java
@SpringBootApplication
@EnableDiscoveryClient
public class GatewayServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(GatewayServiceApplication.class, args);
    }
}
```

La configuración de rutas ya está en config-server.

---

## Fase 7: Ejecutar Instancias Múltiples

Para ejecutar 2 instancias de cada microservicio:

**Instancia 1** (puerto por defecto del config):
```bash
mvn spring-boot:run
```

**Instancia 2** (puerto alternativo):
```bash
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8082
```

Para products-service:
```bash
# Terminal 1
cd products-service
mvn spring-boot:run

# Terminal 2
cd products-service
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8082
```

Repetir para orders (8091/8092), logistics (8101/8102), users (8111/8112).

---

## Fase 8: Scripts de Ejecución

Ver archivo `scripts_ejecucion_completo.sh` incluido.

---

## Fase 9: Pruebas con curl

Ver archivo `scripts_pruebas.sh` incluido.

---

## Checklist Final

- [ ] Eureka Server ejecutándose en :8761
- [ ] Config Server ejecutándose en :8888
- [ ] Products Service: 2 instancias (:8081, :8082)
- [ ] Orders Service: 2 instancias (:8091, :8092)
- [ ] Logistics Service: 2 instancias (:8101, :8102)
- [ ] Users Service: 2 instancias (:8111, :8112)
- [ ] Gateway Service ejecutándose en :8080
- [ ] MySQL con 4 bases de datos creadas
- [ ] Todos los servicios registrados en Eureka
- [ ] Swagger UI accesible en todos los microservicios
- [ ] Scripts de pruebas funcionando correctamente

---

## URLs Importantes

- Eureka Dashboard: http://localhost:8761
- Gateway: http://localhost:8080
- Products API: http://localhost:8081/swagger-ui/index.html
- Orders API: http://localhost:8091/swagger-ui/index.html
- Logistics API: http://localhost:8101/swagger-ui/index.html
- Users API: http://localhost:8111/swagger-ui/index.html

---

**¡IMPORTANTE!**: Sigue esta guía paso a paso. Cada microservicio debe seguir la misma estructura. Los ejemplos de código mostrados son plantillas que debes adaptar y completar para cada entidad.
