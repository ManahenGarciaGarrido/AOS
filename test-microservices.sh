#!/bin/bash

# ==========================================
# Script de Prueba de Microservicios con Docker
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
    local max_retries=${3:-60}
    local delay=${4:-3}

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
write_header "SISTEMA DE MICROSERVICIOS - AZULEJOS ROMU (DOCKER)"
echo -e "${CYAN}Autor: Script de Pruebas Automatizado con Docker${NC}"
echo -e "${CYAN}Fecha: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

echo -e "${YELLOW}Este script realizará las siguientes acciones:${NC}"
echo -e "${GRAY}  1. Verificar que Docker esté instalado y funcionando${NC}"
echo -e "${GRAY}  2. Construir y levantar todos los contenedores con Docker Compose${NC}"
echo -e "${GRAY}  3. Verificar que cada servicio esté funcionando${NC}"
echo -e "${GRAY}  4. Ejecutar pruebas de endpoints${NC}"
echo -e "${GRAY}  5. Mostrar resultados de forma visual${NC}"
echo ""

read -p "¿Desea continuar? (S/N): " continue
if [ "$continue" != "S" ] && [ "$continue" != "s" ]; then
    write_info "Script cancelado por el usuario"
    exit 0
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ==========================================
# VERIFICAR DOCKER
# ==========================================

write_header "VERIFICANDO PREREQUISITOS"

write_info "Verificando instalación de Docker..."
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    write_success "Docker encontrado: $docker_version"
else
    write_error "Docker no está instalado o no está en el PATH"
    write_info "Por favor, instala Docker desde: https://docs.docker.com/get-docker/"
    exit 1
fi

write_info "Verificando instalación de Docker Compose..."
if docker compose version &> /dev/null; then
    compose_version=$(docker compose version)
    write_success "Docker Compose encontrado: $compose_version"
else
    write_error "Docker Compose no está disponible"
    exit 1
fi

write_info "Verificando que Docker esté ejecutándose..."
if docker ps &> /dev/null; then
    write_success "Docker está ejecutándose correctamente"
else
    write_error "Docker no está ejecutándose. Por favor, inicia el servicio Docker"
    exit 1
fi

# ==========================================
# DETENER CONTENEDORES PREVIOS
# ==========================================

echo ""
write_header "LIMPIANDO CONTENEDORES PREVIOS"

write_info "Deteniendo contenedores previos si existen..."
cd "$SCRIPT_DIR"
docker compose down &> /dev/null
write_success "Limpieza completada"

# ==========================================
# CONSTRUIR Y LEVANTAR SERVICIOS
# ==========================================

echo ""
write_header "CONSTRUYENDO Y LEVANTANDO SERVICIOS CON DOCKER COMPOSE"

write_info "Iniciando construcción de imágenes..."
echo -e "${YELLOW}NOTA: La primera vez puede tardar varios minutos en descargar imágenes y construir...${NC}"
echo ""

if docker compose up --build -d; then
    write_success "Todos los contenedores se han iniciado correctamente"
else
    write_error "Error al iniciar los contenedores"
    exit 1
fi

echo ""
write_info "Esperando 30 segundos para que los servicios se inicialicen..."
sleep 30

# ==========================================
# VERIFICAR ESTADO DE SERVICIOS
# ==========================================

echo ""
write_header "VERIFICANDO ESTADO DE CONTENEDORES"

write_info "Estado actual de los contenedores:"
docker compose ps

# ==========================================
# VERIFICAR SALUD DE SERVICIOS
# ==========================================

echo ""
write_header "VERIFICANDO SALUD DE SERVICIOS"

declare -a health_checks=(
    "Config Server|http://localhost:8888/actuator/health"
    "Eureka Server|http://localhost:8761/actuator/health"
    "Products Service|http://localhost:8081/actuator/health"
    "Orders Service|http://localhost:8082/actuator/health"
    "Logistics Service|http://localhost:8083/actuator/health"
    "Users Service|http://localhost:8084/actuator/health"
    "Gateway Service|http://localhost:8080/actuator/health"
)

all_healthy=true
for check in "${health_checks[@]}"; do
    IFS='|' read -r name url <<< "$check"

    if ! test_service_health "$name" "$url"; then
        all_healthy=false
        write_error "$name no está saludable"
    fi
    echo ""
done

if [ "$all_healthy" = false ]; then
    write_error "Algunos servicios no están respondiendo correctamente"
    write_info "Verifica los logs con: docker compose logs [nombre-servicio]"
    write_info "Ejemplo: docker compose logs products-service"
fi

write_info "Esperando 15 segundos adicionales para que todos los servicios se registren en Eureka..."
sleep 15

# ==========================================
# FASE DE PRUEBAS DE ENDPOINTS
# ==========================================

write_header "EJECUTANDO PRUEBAS DE ENDPOINTS"

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
if test_api_endpoint "POST /users/users" "http://localhost:8084/users" "POST" \
    '{"username":"admin","password":"admin123","fullName":"Administrador Sistema","email":"admin@azulejosromu.com","role":"ADMIN"}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 6: Login
echo ""
echo -e "${CYAN}═══ TEST 6: Login de Usuario ═══${NC}"
if test_api_endpoint "POST /users/auth/login" "http://localhost:8084/auth/login" "POST" \
    '{"username":"admin","password":"admin123"}'; then
    ((passed++))
else
    ((failed++))
fi
sleep 2

# Prueba 7: Crear Camión
echo ""
echo -e "${CYAN}═══ TEST 7: Crear Camión ═══${NC}"
if test_api_endpoint "POST /logistics/trucks" "http://localhost:8083/trucks" "POST" \
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
# INFORMACIÓN DE URLS Y COMANDOS
# ==========================================

echo ""
write_header "URLs DE LOS SERVICIOS"

echo -e "${YELLOW}Eureka Dashboard:      http://localhost:8761${NC}"
echo -e "${YELLOW}Gateway:               http://localhost:8080${NC}"
echo -e "${YELLOW}Products Service:      http://localhost:8081${NC}"
echo -e "${YELLOW}Orders Service:        http://localhost:8082${NC}"
echo -e "${YELLOW}Logistics Service:     http://localhost:8083${NC}"
echo -e "${YELLOW}Users Service:         http://localhost:8084${NC}"

echo ""
echo -e "${CYAN}═══ Swagger UI ═══${NC}"
echo -e "${YELLOW}Products:  http://localhost:8081/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Orders:    http://localhost:8082/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Logistics: http://localhost:8083/swagger-ui/index.html${NC}"
echo -e "${YELLOW}Users:     http://localhost:8084/swagger-ui/index.html${NC}"

echo ""
write_header "COMANDOS ÚTILES DE DOCKER"

echo -e "${CYAN}Ver logs de todos los servicios:${NC}"
echo -e "${GRAY}  docker compose logs -f${NC}"

echo -e "${CYAN}Ver logs de un servicio específico:${NC}"
echo -e "${GRAY}  docker compose logs -f products-service${NC}"

echo -e "${CYAN}Detener todos los servicios:${NC}"
echo -e "${GRAY}  docker compose down${NC}"

echo -e "${CYAN}Detener y eliminar volúmenes:${NC}"
echo -e "${GRAY}  docker compose down -v${NC}"

echo -e "${CYAN}Ver estado de contenedores:${NC}"
echo -e "${GRAY}  docker compose ps${NC}"

echo ""
write_success "Script de pruebas completado!"
write_info "Los servicios están ejecutándose en contenedores Docker"
write_info "Para detenerlos ejecuta: docker compose down"

echo ""
