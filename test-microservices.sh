#!/bin/bash

# ==========================================
# Script de Prueba de Microservicios con Docker
# Azulejos Romu - Bash (Linux/Mac)
# Prueba completa de los 18 Casos de Uso
# ==========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Funciones
print_header() {
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

test_service_health() {
    local service_name=$1
    local url=$2
    local max_retries=${3:-60}
    local delay=${4:-3}
    
    print_info "Verificando $service_name en $url..."
    
    for ((i=1; i<=max_retries; i++)); do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name esta funcionando! (Intento $i/$max_retries)"
            return 0
        fi
        echo -n "."
        sleep $delay
    done
    
    echo ""
    print_error "$service_name no responde despues de $max_retries intentos"
    return 1
}

test_api_endpoint() {
    local case_number=$1
    local case_name=$2
    local url=$3
    local method=${4:-GET}
    local body=$5
    
    echo ""
    echo -e "${CYAN}=== $case_number: $case_name ===${NC}"
    echo -e "   URL: $url"
    echo -e "   Method: $method"
    
    if [ "$method" == "POST" ] || [ "$method" == "PUT" ]; then
        if [ -n "$body" ]; then
            echo -e "   Body: $body"
            response=$(curl -s -X "$method" -H "Content-Type: application/json" -d "$body" "$url" 2>&1)
        else
            response=$(curl -s -X "$method" "$url" 2>&1)
        fi
    else
        response=$(curl -s -X "$method" "$url" 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Caso de uso completado exitosamente"
        echo "PASS|$case_number|$case_name"
        return 0
    else
        print_error "Error en la peticion"
        echo "FAIL|$case_number|$case_name"
        return 1
    fi
}

# ==========================================
# INICIO DEL SCRIPT
# ==========================================

clear
print_header "SISTEMA DE MICROSERVICIOS - AZULEJOS ROMU"
echo -e "${CYAN}Prueba Completa de los 18 Casos de Uso${NC}"
echo -e "${CYAN}Fecha: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

echo -e "${YELLOW}Este script realizara las siguientes acciones:${NC}"
echo "  1. Verificar que Docker este instalado y funcionando"
echo "  2. Construir y levantar todos los contenedores"
echo "  3. Verificar que cada servicio este funcionando"
echo "  4. Ejecutar pruebas de los 18 casos de uso"
echo "  5. Mostrar resultados finales"
echo ""

read -p "Desea continuar? (S/N): " continue
if [ "$continue" != "S" ] && [ "$continue" != "s" ]; then
    print_info "Script cancelado por el usuario"
    exit 0
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_FILE="/tmp/test_results.txt"
> "$RESULTS_FILE"

# ==========================================
# VERIFICAR DOCKER
# ==========================================

print_header "VERIFICANDO PREREQUISITOS"

print_info "Verificando instalacion de Docker..."
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    print_success "Docker encontrado: $docker_version"
else
    print_error "Docker no esta instalado"
    exit 1
fi

print_info "Verificando instalacion de Docker Compose..."
if docker compose version &> /dev/null; then
    compose_version=$(docker compose version)
    print_success "Docker Compose encontrado: $compose_version"
else
    print_error "Docker Compose no esta disponible"
    exit 1
fi

print_info "Verificando que Docker este ejecutandose..."
if docker ps &> /dev/null; then
    print_success "Docker esta ejecutandose correctamente"
else
    print_error "Docker no esta ejecutandose"
    exit 1
fi

# ==========================================
# DETENER CONTENEDORES PREVIOS
# ==========================================

print_header "LIMPIANDO CONTENEDORES PREVIOS"

print_info "Deteniendo contenedores previos si existen..."
cd "$PROJECT_ROOT"
docker compose down &> /dev/null
print_success "Limpieza completada"

# ==========================================
# CONSTRUIR Y LEVANTAR SERVICIOS
# ==========================================

print_header "CONSTRUYENDO Y LEVANTANDO SERVICIOS"

print_info "Iniciando construccion de imagenes..."
echo -e "${YELLOW}NOTA: La primera vez puede tardar varios minutos...${NC}"
echo ""

if docker compose up --build -d; then
    print_success "Todos los contenedores se han iniciado correctamente"
else
    print_error "Error al iniciar los contenedores"
    exit 1
fi

echo ""
print_info "Esperando 30 segundos para que los servicios se inicialicen..."
sleep 30

# ==========================================
# VERIFICAR ESTADO DE SERVICIOS
# ==========================================

print_header "VERIFICANDO ESTADO DE CONTENEDORES"
docker compose ps

# ==========================================
# VERIFICAR SALUD DE SERVICIOS
# ==========================================

print_header "VERIFICANDO SALUD DE SERVICIOS"

test_service_health "Config Server" "http://localhost:8888/actuator/health"
echo ""
test_service_health "Eureka Server" "http://localhost:8761/actuator/health"
echo ""
test_service_health "Products Service" "http://localhost:8081/actuator/health"
echo ""
test_service_health "Orders Service" "http://localhost:8082/actuator/health"
echo ""
test_service_health "Logistics Service" "http://localhost:8083/actuator/health"
echo ""
test_service_health "Users Service" "http://localhost:8084/actuator/health"
echo ""
test_service_health "Gateway Service" "http://localhost:8080/actuator/health"
echo ""

print_info "Esperando 15 segundos para que los servicios se registren en Eureka..."
sleep 15

# ==========================================
# PRUEBAS DE LOS 18 CASOS DE USO
# ==========================================

print_header "EJECUTANDO PRUEBAS DE LOS 18 CASOS DE USO"

echo -e "${MAGENTA}\n*** BC-1: GESTION DE PRODUCTOS Y STOCK ***${NC}"

# CU-01
test_api_endpoint "CU-01" "Mantener Catalogo de Productos - Crear Categoria" \
    "http://localhost:8081/categories" "POST" \
    '{"code":"AZUL001","name":"Azulejos Bano","description":"Azulejos para bano"}' >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-01" "Mantener Catalogo de Productos - Crear Proveedor" \
    "http://localhost:8081/suppliers" "POST" \
    '{"name":"Ceramicas Romu S.L.","nif":"B12345678","city":"Valencia","country":"Espana"}' >> "$RESULTS_FILE"
sleep 1

# CU-02
test_api_endpoint "CU-02" "Gestionar Proveedores - Listar Proveedores" \
    "http://localhost:8081/suppliers" "GET" >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-02" "Gestionar Proveedores - Buscar por NIF" \
    "http://localhost:8081/suppliers/nif/B12345678" "GET" >> "$RESULTS_FILE"
sleep 1

# CU-03
test_api_endpoint "CU-03" "Consultar Stock Disponible - Crear Almacen" \
    "http://localhost:8081/warehouses" "POST" \
    '{"code":"ALM001","name":"Almacen Central","city":"Valencia","latitude":39.4699,"longitude":-0.3763}' >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-03" "Consultar Stock Disponible - Listar Stock" \
    "http://localhost:8081/stock" "GET" >> "$RESULTS_FILE"
sleep 1

# CU-04
test_api_endpoint "CU-04" "Controlar Movimientos de Stock - Ajustar Stock" \
    "http://localhost:8081/stock/adjust" "POST" \
    '{"productId":1,"warehouseId":1,"quantity":100,"movementType":"IN","notes":"Entrada inicial","userId":1}' >> "$RESULTS_FILE"
sleep 1

# CU-05
test_api_endpoint "CU-05" "Generar Alertas de Reposicion - Stock Bajo" \
    "http://localhost:8081/stock/low-stock" "GET" >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-05" "Generar Alertas de Reposicion - Productos a Reponer" \
    "http://localhost:8081/stock/reorder" "GET" >> "$RESULTS_FILE"
sleep 1

echo -e "${MAGENTA}\n*** BC-2: GESTION DE PEDIDOS ***${NC}"

# CU-06
test_api_endpoint "CU-06" "Realizar Pedido de Cliente" \
    "http://localhost:8082/orders" "POST" \
    '{"orderNumber":"ORD-2025-001","orderType":"CUSTOMER","customerId":1,"status":"PENDING","deliveryType":"HOME","deliveryAddress":"Calle Mayor 25","totalAmount":775.00}' >> "$RESULTS_FILE"
sleep 1

# CU-07
test_api_endpoint "CU-07" "Gestionar Pedido de Reposicion" \
    "http://localhost:8082/orders" "POST" \
    '{"orderNumber":"ORD-2025-002","orderType":"REPLENISHMENT","warehouseId":1,"status":"PENDING","totalAmount":1500.00}' >> "$RESULTS_FILE"
sleep 1

# CU-08
test_api_endpoint "CU-08" "Gestionar Pedido a Proveedor" \
    "http://localhost:8082/orders" "POST" \
    '{"orderNumber":"ORD-2025-003","orderType":"SUPPLIER","supplierId":1,"status":"PENDING","totalAmount":5000.00}' >> "$RESULTS_FILE"
sleep 1

# CU-09
test_api_endpoint "CU-09" "Actualizar Estado de Pedido" \
    "http://localhost:8082/orders/1/status" "PUT" \
    '{"status":"PREPARING","userId":1,"notes":"Pedido en preparacion"}' >> "$RESULTS_FILE"
sleep 1

# CU-10
test_api_endpoint "CU-10" "Consultar Historial de Pedidos - Listar Todos" \
    "http://localhost:8082/orders" "GET" >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-10" "Consultar Historial de Pedidos - Por Tipo" \
    "http://localhost:8082/orders/type/CUSTOMER" "GET" >> "$RESULTS_FILE"
sleep 1

echo -e "${MAGENTA}\n*** BC-3: LOGISTICA Y DISTRIBUCION ***${NC}"

# CU-11
test_api_endpoint "CU-11" "Gestionar Flota de Camiones - Crear Camion" \
    "http://localhost:8083/trucks" "POST" \
    '{"licensePlate":"1234ABC","brand":"Mercedes","model":"Actros","year":2022,"status":"DISPONIBLE"}' >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-11" "Gestionar Flota de Camiones - Listar Camiones" \
    "http://localhost:8083/trucks" "GET" >> "$RESULTS_FILE"
sleep 1

# CU-12
test_api_endpoint "CU-12" "Optimizar Rutas de Entrega - Crear Conductor" \
    "http://localhost:8083/drivers" "POST" \
    '{"name":"Juan Perez","nif":"12345678A","licenseNumber":"B1234567","status":"DISPONIBLE"}' >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-12" "Optimizar Rutas de Entrega - Optimizar Ruta" \
    "http://localhost:8083/routes/optimize" "POST" \
    '{"truckId":1,"driverId":1,"orderIds":[1,2,3]}' >> "$RESULTS_FILE"
sleep 1

# CU-13
test_api_endpoint "CU-13" "Seguimiento GPS en Tiempo Real - Registrar Posicion" \
    "http://localhost:8083/tracking" "POST" \
    '{"truckId":1,"routeId":1,"latitude":40.0381,"longitude":-6.0893,"speed":65.5}' >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-13" "Seguimiento GPS en Tiempo Real - Obtener Ultima Posicion" \
    "http://localhost:8083/tracking/truck/1/latest" "GET" >> "$RESULTS_FILE"
sleep 1

# CU-14
test_api_endpoint "CU-14" "Asignar Entregas a Repartidores - Ver Rutas del Conductor" \
    "http://localhost:8083/routes/driver/1" "GET" >> "$RESULTS_FILE"
sleep 1

echo -e "${MAGENTA}\n*** BC-4: GESTION DE USUARIOS Y SEGURIDAD ***${NC}"

# CU-15
test_api_endpoint "CU-15" "Autenticar Usuario - Crear Usuario" \
    "http://localhost:8084/users" "POST" \
    '{"username":"admin","password":"admin123","fullName":"Administrador Sistema","email":"admin@azulejosromu.com","role":"ADMIN"}' >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-15" "Autenticar Usuario - Login" \
    "http://localhost:8084/auth/login" "POST" \
    '{"username":"admin","password":"admin123"}' >> "$RESULTS_FILE"
sleep 1

# CU-16
test_api_endpoint "CU-16" "Gestionar Roles y Permisos - Listar Usuarios" \
    "http://localhost:8084/users" "GET" >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-16" "Gestionar Roles y Permisos - Buscar por Rol" \
    "http://localhost:8084/users/role/ADMIN" "GET" >> "$RESULTS_FILE"
sleep 1

# CU-17
test_api_endpoint "CU-17" "Asignar Mozos a Almacenes - Crear Asignacion" \
    "http://localhost:8084/warehouse-assignments" "POST" \
    "{\"userId\":1,\"warehouseId\":1,\"assignmentDate\":\"$(date +%Y-%m-%d)\",\"isCurrent\":true}" >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-17" "Asignar Mozos a Almacenes - Ver Asignaciones Actuales" \
    "http://localhost:8084/warehouse-assignments/user/1/current" "GET" >> "$RESULTS_FILE"
sleep 1

# CU-18
test_api_endpoint "CU-18" "Auditar Operaciones - Registrar Evento" \
    "http://localhost:8084/audit-logs" "POST" \
    '{"userId":1,"action":"CREATE_ORDER","entityType":"ORDER","entityId":1,"details":"Pedido creado por el usuario admin"}' >> "$RESULTS_FILE"
sleep 1

test_api_endpoint "CU-18" "Auditar Operaciones - Consultar Auditoria de Usuario" \
    "http://localhost:8084/audit-logs/user/1" "GET" >> "$RESULTS_FILE"
sleep 1

# ==========================================
# RESUMEN DE PRUEBAS
# ==========================================

print_header "RESUMEN DE PRUEBAS DE LOS 18 CASOS DE USO"

total=$(wc -l < "$RESULTS_FILE")
passed=$(grep -c "^PASS" "$RESULTS_FILE")
failed=$(grep -c "^FAIL" "$RESULTS_FILE")

echo -e "${CYAN}Casos de Uso por Business Capability:${NC}"

echo -e "\n${YELLOW}BC-1: GESTION DE PRODUCTOS Y STOCK${NC}"
grep "^PASS|CU-0[1-5]" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_success "$case: $name"
done
grep "^FAIL|CU-0[1-5]" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_error "$case: $name"
done

echo -e "\n${YELLOW}BC-2: GESTION DE PEDIDOS${NC}"
grep "^PASS|CU-\(06\|07\|08\|09\|10\)" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_success "$case: $name"
done
grep "^FAIL|CU-\(06\|07\|08\|09\|10\)" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_error "$case: $name"
done

echo -e "\n${YELLOW}BC-3: LOGISTICA Y DISTRIBUCION${NC}"
grep "^PASS|CU-1[1-4]" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_success "$case: $name"
done
grep "^FAIL|CU-1[1-4]" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_error "$case: $name"
done

echo -e "\n${YELLOW}BC-4: GESTION DE USUARIOS Y SEGURIDAD${NC}"
grep "^PASS|CU-1[5-8]" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_success "$case: $name"
done
grep "^FAIL|CU-1[5-8]" "$RESULTS_FILE" | while IFS='|' read -r status case name; do
    print_error "$case: $name"
done

echo ""
echo -e "${CYAN}====================================${NC}"
echo -e "${CYAN}Total de pruebas: $total${NC}"
echo -e "${GREEN}Exitosas: $passed${NC}"
echo -e "${RED}Fallidas: $failed${NC}"
if [ $total -gt 0 ]; then
    percentage=$(awk "BEGIN {printf \"%.2f\", ($passed/$total)*100}")
    echo -e "${CYAN}Porcentaje de exito: $percentage%${NC}"
fi
echo -e "${CYAN}====================================${NC}"

# ==========================================
# INFORMACION DE URLS Y COMANDOS
# ==========================================

print_header "URLs DE LOS SERVICIOS"

echo -e "${YELLOW}Eureka Dashboard:      http://localhost:8761${NC}"
echo -e "${YELLOW}Gateway:               http://localhost:8080${NC}"
echo -e "${YELLOW}Products Service:      http://localhost:8081${NC}"
echo -e "${YELLOW}Orders Service:        http://localhost:8082${NC}"
echo -e "${YELLOW}Logistics Service:     http://localhost:8083${NC}"
echo -e "${YELLOW}Users Service:         http://localhost:8084${NC}"

echo ""
echo -e "${CYAN}=== Swagger UI ===${NC}"
echo -e "${YELLOW}Products:  http://localhost:8081/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Orders:    http://localhost:8082/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Logistics: http://localhost:8083/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Users:     http://localhost:8084/swagger-ui/index.html${NC}"

print_header "COMANDOS UTILES DE DOCKER"

echo -e "${CYAN}Ver logs de todos los servicios:${NC}"
echo "  docker compose logs -f"

echo -e "${CYAN}Ver logs de un servicio especifico:${NC}"
echo "  docker compose logs -f products-service"

echo -e "${CYAN}Detener todos los servicios:${NC}"
echo "  docker compose down"

echo -e "${CYAN}Detener y eliminar volumenes:${NC}"
echo "  docker compose down -v"

echo -e "${CYAN}Ver estado de contenedores:${NC}"
echo "  docker compose ps"

echo ""
if [ $failed -eq 0 ]; then
    print_success "Todos los casos de uso pasaron las pruebas!"
else
    echo -e "${RED}Algunos casos de uso fallaron. Revisa los logs para mas detalles.${NC}"
fi
print_info "Los servicios estan ejecutandose en contenedores Docker"
print_info "Para detenerlos ejecuta: docker compose down"

echo ""
