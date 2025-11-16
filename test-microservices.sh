#!/bin/bash

# ==========================================
# Script de Prueba de Microservicios
# Azulejos Romu - Linux/Unix Bash
# ==========================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Funciones de utilidad
write_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

write_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

write_error() {
    echo -e "${RED}✗ $1${NC}"
}

write_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Función para probar la salud de un servicio
test_service_health() {
    local service_name=$1
    local url=$2
    local max_retries=${3:-30}
    local delay=${4:-2}

    write_info "Verificando $service_name en $url..."

    for ((i=1; i<=max_retries; i++)); do
        if curl -s -f "$url" > /dev/null 2>&1; then
            write_success "$service_name está funcionando! (Intento $i/$max_retries)"
            return 0
        fi
        echo -n "."
        sleep $delay
    done

    echo ""
    write_error "$service_name no responde después de $max_retries intentos"
    return 1
}

# Función para iniciar un servicio
start_service() {
    local service_name=$1
    local path=$2
    local port=$3

    write_info "Iniciando $service_name en puerto $port..."

    # Iniciar en segundo plano usando gnome-terminal, xterm o directamente en background
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "cd '$path' && echo 'Iniciando $service_name...' && mvn spring-boot:run; exec bash" &
    elif command -v xterm &> /dev/null; then
        xterm -e "cd '$path' && echo 'Iniciando $service_name...' && mvn spring-boot:run" &
    else
        # Si no hay terminal gráfica, ejecutar en background
        (cd "$path" && mvn spring-boot:run > "/tmp/$service_name.log" 2>&1) &
        write_info "Servicio iniciado en background. Log en /tmp/$service_name.log"
    fi

    sleep 3
    write_success "$service_name iniciado"
}

# Función para probar un endpoint
test_api_endpoint() {
    local name=$1
    local url=$2
    local method=${3:-GET}
    local body=$4

    write_info "Probando: $name"
    echo -e "${GRAY}   URL: $url${NC}"

    if [ "$method" = "POST" ] && [ -n "$body" ]; then
        response=$(curl -s -X POST -H "Content-Type: application/json" -d "$body" "$url" 2>&1)
        exit_code=$?
    else
        response=$(curl -s -X "$method" "$url" 2>&1)
        exit_code=$?
    fi

    if [ $exit_code -eq 0 ]; then
        write_success "Respuesta recibida exitosamente"
        echo -e "${GRAY}   Datos: ${MAGENTA}$(echo "$response" | head -c 100)...${NC}"
        return 0
    else
        write_error "Error en la petición"
        return 1
    fi
}

# ==========================================
# INICIO DEL SCRIPT
# ==========================================

clear
write_header "SISTEMA DE MICROSERVICIOS - AZULEJOS ROMU"
echo -e "${CYAN}Autor: Script de Pruebas Automatizado${NC}"
echo -e "${CYAN}Fecha: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

echo -e "${YELLOW}Este script realizará las siguientes acciones:${NC}"
echo -e "${GRAY}  1. Iniciar todos los microservicios en terminales/background${NC}"
echo -e "${GRAY}  2. Verificar que cada servicio esté funcionando${NC}"
echo -e "${GRAY}  3. Ejecutar pruebas de endpoints${NC}"
echo -e "${GRAY}  4. Mostrar resultados de forma visual${NC}"
echo ""

read -p "¿Desea continuar? (S/N): " continue
if [ "$continue" != "S" ] && [ "$continue" != "s" ]; then
    write_info "Script cancelado por el usuario"
    exit 0
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ==========================================
# FASE 1: SERVICIOS DE INFRAESTRUCTURA
# ==========================================

write_header "FASE 1: Iniciando Servicios de Infraestructura"

# Eureka Server
start_service "Eureka Server" "$SCRIPT_DIR/codigo/eureka-server" 8761
echo ""

# Esperar a que Eureka esté listo
if ! test_service_health "Eureka Server" "http://localhost:8761"; then
    write_error "No se pudo iniciar Eureka Server. Abortando..."
    exit 1
fi

echo ""
sleep 5

# Config Server
start_service "Config Server" "$SCRIPT_DIR/codigo/config-server" 8888
echo ""

if ! test_service_health "Config Server" "http://localhost:8888/actuator/health"; then
    write_error "No se pudo iniciar Config Server. Abortando..."
    exit 1
fi

echo ""
write_success "Servicios de infraestructura iniciados correctamente"
sleep 10

# ==========================================
# FASE 2: MICROSERVICIOS DE NEGOCIO
# ==========================================

write_header "FASE 2: Iniciando Microservicios de Negocio"

# Products Service
start_service "Products Service" "$SCRIPT_DIR/codigo/products-service" 8081
echo ""
sleep 15

if ! test_service_health "Products Service" "http://localhost:8081/actuator/health" 40; then
    write_error "Products Service no responde, pero continuamos..."
fi

# Orders Service
start_service "Orders Service" "$SCRIPT_DIR/codigo/orders-service" 8091
echo ""
sleep 15

if ! test_service_health "Orders Service" "http://localhost:8091/actuator/health" 40; then
    write_error "Orders Service no responde, pero continuamos..."
fi

# Logistics Service
start_service "Logistics Service" "$SCRIPT_DIR/codigo/logistics-service" 8101
echo ""
sleep 15

if ! test_service_health "Logistics Service" "http://localhost:8101/actuator/health" 40; then
    write_error "Logistics Service no responde, pero continuamos..."
fi

# Users Service
start_service "Users Service" "$SCRIPT_DIR/codigo/users-service" 8111
echo ""
sleep 15

if ! test_service_health "Users Service" "http://localhost:8111/actuator/health" 40; then
    write_error "Users Service no responde, pero continuamos..."
fi

# Gateway Service
start_service "Gateway Service" "$SCRIPT_DIR/codigo/gateway-service" 8080
echo ""
sleep 15

if ! test_service_health "Gateway Service" "http://localhost:8080/actuator/health" 40; then
    write_error "Gateway Service no responde, pero continuamos..."
fi

echo ""
write_success "Todos los microservicios han sido iniciados"
write_info "Esperando 20 segundos para que todos los servicios se registren en Eureka..."
sleep 20

# ==========================================
# FASE 3: PRUEBAS DE ENDPOINTS
# ==========================================

write_header "FASE 3: Ejecutando Pruebas de Endpoints"

declare -a test_results
passed=0
failed=0

# Prueba 1: Crear Categoría
echo ""
echo -e "${CYAN}═══ TEST 1: Crear Categoría ═══${NC}"
if test_api_endpoint "POST /products/categories" "http://localhost:8081/categories" "POST" \
    '{"code":"AZUL001","name":"Azulejos Baño","description":"Azulejos para baño"}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 2: Listar Categorías
echo ""
echo -e "${CYAN}═══ TEST 2: Listar Categorías ═══${NC}"
if test_api_endpoint "GET /products/categories" "http://localhost:8081/categories"; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 3: Crear Proveedor
echo ""
echo -e "${CYAN}═══ TEST 3: Crear Proveedor ═══${NC}"
if test_api_endpoint "POST /products/suppliers" "http://localhost:8081/suppliers" "POST" \
    '{"name":"Cerámicas Romu S.L.","nif":"B12345678","city":"Valencia","country":"España","phone":"+34 960 000 000","email":"contacto@ceramicasromu.com"}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 4: Crear Almacén
echo ""
echo -e "${CYAN}═══ TEST 4: Crear Almacén ═══${NC}"
if test_api_endpoint "POST /products/warehouses" "http://localhost:8081/warehouses" "POST" \
    '{"code":"ALM001","name":"Almacén Central Valencia","city":"Valencia","latitude":39.4699,"longitude":-0.3763}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 5: Crear Usuario
echo ""
echo -e "${CYAN}═══ TEST 5: Crear Usuario ═══${NC}"
if test_api_endpoint "POST /users/users" "http://localhost:8111/users" "POST" \
    '{"username":"admin","password":"admin123","fullName":"Administrador Sistema","email":"admin@azulejosromu.com","role":"ADMIN"}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 6: Login
echo ""
echo -e "${CYAN}═══ TEST 6: Login de Usuario ═══${NC}"
if test_api_endpoint "POST /users/auth/login" "http://localhost:8111/auth/login" "POST" \
    '{"username":"admin","password":"admin123"}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 7: Crear Camión
echo ""
echo -e "${CYAN}═══ TEST 7: Crear Camión ═══${NC}"
if test_api_endpoint "POST /logistics/trucks" "http://localhost:8101/trucks" "POST" \
    '{"licensePlate":"1234ABC","brand":"Mercedes","model":"Actros","year":2022,"status":"DISPONIBLE"}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 8: Verificar Eureka
echo ""
echo -e "${CYAN}═══ TEST 8: Servicios Registrados en Eureka ═══${NC}"
if test_api_endpoint "GET Eureka Applications" "http://localhost:8761/eureka/apps"; then
    ((passed++))
else
    ((failed++))
fi

# ==========================================
# RESUMEN DE PRUEBAS
# ==========================================

total=$((passed + failed))

echo ""
write_header "RESUMEN DE PRUEBAS"

echo -e "${CYAN}════════════════════════════════════${NC}"
echo -e "${WHITE}Total de pruebas: $total${NC}"
echo -e "${GREEN}Exitosas: $passed${NC}"
echo -e "${RED}Fallidas: $failed${NC}"
echo -e "${CYAN}════════════════════════════════════${NC}"

# ==========================================
# INFORMACIÓN DE URLS
# ==========================================

echo ""
write_header "URLs DE LOS SERVICIOS"

echo -e "${YELLOW}Eureka Dashboard:      http://localhost:8761${NC}"
echo -e "${YELLOW}Gateway:               http://localhost:8080${NC}"
echo -e "${YELLOW}Products Service:      http://localhost:8081${NC}"
echo -e "${YELLOW}Orders Service:        http://localhost:8091${NC}"
echo -e "${YELLOW}Logistics Service:     http://localhost:8101${NC}"
echo -e "${YELLOW}Users Service:         http://localhost:8111${NC}"

echo ""
echo -e "${CYAN}═══ Swagger UI ═══${NC}"
echo -e "${YELLOW}Products:  http://localhost:8081/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Orders:    http://localhost:8091/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Logistics: http://localhost:8101/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Users:     http://localhost:8111/swagger-ui/index.html${NC}"

echo ""
write_success "Script de pruebas completado!"
write_info "Los servicios seguirán ejecutándose en segundo plano"
write_info "Para detener todos los servicios, ejecuta: pkill -f 'spring-boot:run'"

echo ""
