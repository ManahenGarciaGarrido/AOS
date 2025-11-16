# ==========================================
# Script de Prueba de Microservicios con Docker
# Azulejos Romu - Windows PowerShell
# ==========================================

# Configuración de colores
$host.UI.RawUI.ForegroundColor = "White"

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "================================================================" "Cyan"
    Write-ColorOutput "  $Title" "Cyan"
    Write-ColorOutput "================================================================" "Cyan"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[OK] $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Yellow"
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxRetries = 60,
        [int]$DelaySeconds = 3
    )

    Write-Info "Verificando $ServiceName en $Url..."

    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 3 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Success "$ServiceName esta funcionando! (Intento $i/$MaxRetries)"
                return $true
            }
        }
        catch {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    Write-Host ""
    Write-Error "$ServiceName no responde despues de $MaxRetries intentos"
    return $false
}

function Test-ApiEndpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [object]$Body = $null
    )

    Write-Info "Probando: $Name"
    Write-Host "   URL: $Url" -ForegroundColor Gray

    try {
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Body $jsonBody -ContentType "application/json" -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -ErrorAction Stop
        }

        Write-Success "Respuesta recibida exitosamente"
        Write-Host "   Datos: " -NoNewline -ForegroundColor Gray

        if ($response -is [System.Array]) {
            Write-Host "$($response.Count) elementos" -ForegroundColor Magenta
        } elseif ($response -is [PSCustomObject]) {
            Write-Host "Objeto JSON" -ForegroundColor Magenta
        } else {
            Write-Host "$response" -ForegroundColor Magenta
        }

        return $true
    }
    catch {
        Write-Error "Error en la peticion: $($_.Exception.Message)"
        return $false
    }
}

# ==========================================
# INICIO DEL SCRIPT
# ==========================================

Clear-Host
Write-Header "SISTEMA DE MICROSERVICIOS - AZULEJOS ROMU (DOCKER)"
Write-ColorOutput "Autor: Script de Pruebas Automatizado con Docker" "Cyan"
$fechaActual = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-ColorOutput "Fecha: $fechaActual" "Cyan"
Write-Host ""

Write-ColorOutput "Este script realizara las siguientes acciones:" "Yellow"
Write-Host "  1. Verificar que Docker este instalado y funcionando" -ForegroundColor Gray
Write-Host "  2. Construir y levantar todos los contenedores con Docker Compose" -ForegroundColor Gray
Write-Host "  3. Verificar que cada servicio este funcionando" -ForegroundColor Gray
Write-Host "  4. Ejecutar pruebas de endpoints" -ForegroundColor Gray
Write-Host "  5. Mostrar resultados de forma visual" -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "Desea continuar? (S/N)"
if ($continue -ne "S" -and $continue -ne "s") {
    Write-Info "Script cancelado por el usuario"
    exit
}

$projectRoot = $PSScriptRoot

# ==========================================
# VERIFICAR DOCKER
# ==========================================

Write-Header "VERIFICANDO PREREQUISITOS"

Write-Info "Verificando instalacion de Docker..."
try {
    $dockerVersion = docker --version
    Write-Success "Docker encontrado: $dockerVersion"
} catch {
    Write-Error "Docker no esta instalado o no esta en el PATH"
    Write-Info "Por favor, instala Docker Desktop desde: https://www.docker.com/products/docker-desktop"
    exit 1
}

Write-Info "Verificando instalacion de Docker Compose..."
try {
    $composeVersion = docker compose version
    Write-Success "Docker Compose encontrado: $composeVersion"
} catch {
    Write-Error "Docker Compose no esta disponible"
    exit 1
}

Write-Info "Verificando que Docker este ejecutandose..."
try {
    docker ps | Out-Null
    Write-Success "Docker esta ejecutandose correctamente"
} catch {
    Write-Error "Docker no esta ejecutandose. Por favor, inicia Docker Desktop"
    exit 1
}

# ==========================================
# DETENER CONTENEDORES PREVIOS
# ==========================================

Write-Host ""
Write-Header "LIMPIANDO CONTENEDORES PREVIOS"

Write-Info "Deteniendo contenedores previos si existen..."
cd $projectRoot
docker compose down 2>&1 | Out-Null
Write-Success "Limpieza completada"

# ==========================================
# CONSTRUIR Y LEVANTAR SERVICIOS
# ==========================================

Write-Host ""
Write-Header "CONSTRUYENDO Y LEVANTANDO SERVICIOS CON DOCKER COMPOSE"

Write-Info "Iniciando construccion de imagenes..."
Write-ColorOutput "NOTA: La primera vez puede tardar varios minutos en descargar imagenes y construir..." "Yellow"
Write-Host ""

$dockerComposeOutput = docker compose up --build -d 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "Todos los contenedores se han iniciado correctamente"
} else {
    Write-Error "Error al iniciar los contenedores"
    Write-Host $dockerComposeOutput
    exit 1
}

Write-Host ""
Write-Info "Esperando 30 segundos para que los servicios se inicialicen..."
Start-Sleep -Seconds 30

# ==========================================
# VERIFICAR ESTADO DE SERVICIOS
# ==========================================

Write-Host ""
Write-Header "VERIFICANDO ESTADO DE CONTENEDORES"

Write-Info "Estado actual de los contenedores:"
docker compose ps

# ==========================================
# VERIFICAR SALUD DE SERVICIOS
# ==========================================

Write-Host ""
Write-Header "VERIFICANDO SALUD DE SERVICIOS"

$healthChecks = @(
    @{ Name = "MySQL Database"; Url = "http://localhost:3306" },
    @{ Name = "Config Server"; Url = "http://localhost:8888/actuator/health" },
    @{ Name = "Eureka Server"; Url = "http://localhost:8761/actuator/health" },
    @{ Name = "Products Service"; Url = "http://localhost:8081/actuator/health" },
    @{ Name = "Orders Service"; Url = "http://localhost:8082/actuator/health" },
    @{ Name = "Logistics Service"; Url = "http://localhost:8083/actuator/health" },
    @{ Name = "Users Service"; Url = "http://localhost:8084/actuator/health" },
    @{ Name = "Gateway Service"; Url = "http://localhost:8080/actuator/health" }
)

$allHealthy = $true
foreach ($check in $healthChecks) {
    # Skip MySQL TCP check
    if ($check.Name -eq "MySQL Database") {
        Write-Info "MySQL se verificara indirectamente a traves de los servicios"
        continue
    }

    if (-not (Test-ServiceHealth -ServiceName $check.Name -Url $check.Url)) {
        $allHealthy = $false
        Write-Error "$($check.Name) no esta saludable"
    }
    Write-Host ""
}

if (-not $allHealthy) {
    Write-Error "Algunos servicios no estan respondiendo correctamente"
    Write-Info "Verifica los logs con: docker compose logs [nombre-servicio]"
    Write-Info "Ejemplo: docker compose logs products-service"
}

Write-Info "Esperando 15 segundos adicionales para que todos los servicios se registren en Eureka..."
Start-Sleep -Seconds 15

# ==========================================
# FASE DE PRUEBAS DE ENDPOINTS
# ==========================================

Write-Header "EJECUTANDO PRUEBAS DE ENDPOINTS"

$testResults = @()

# Prueba 1: Crear Categoria
Write-Host ""
Write-ColorOutput "=== TEST 1: Crear Categoria ===" "Cyan"
$category = @{
    code = "AZUL001"
    name = "Azulejos Bano"
    description = "Azulejos para bano"
}
$result = Test-ApiEndpoint -Name "POST /products/categories" -Url "http://localhost:8081/categories" -Method "POST" -Body $category
$testResults += @{ Test = "Crear Categoria"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 2: Listar Categorias
Write-Host ""
Write-ColorOutput "=== TEST 2: Listar Categorias ===" "Cyan"
$result = Test-ApiEndpoint -Name "GET /products/categories" -Url "http://localhost:8081/categories"
$testResults += @{ Test = "Listar Categorias"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 3: Crear Proveedor
Write-Host ""
Write-ColorOutput "=== TEST 3: Crear Proveedor ===" "Cyan"
$supplier = @{
    name = "Ceramicas Romu S.L."
    nif = "B12345678"
    city = "Valencia"
    country = "Espana"
    phone = "+34 960 000 000"
    email = "contacto@ceramicasromu.com"
}
$result = Test-ApiEndpoint -Name "POST /products/suppliers" -Url "http://localhost:8081/suppliers" -Method "POST" -Body $supplier
$testResults += @{ Test = "Crear Proveedor"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 4: Crear Almacen
Write-Host ""
Write-ColorOutput "=== TEST 4: Crear Almacen ===" "Cyan"
$warehouse = @{
    code = "ALM001"
    name = "Almacen Central Valencia"
    city = "Valencia"
    latitude = 39.4699
    longitude = -0.3763
}
$result = Test-ApiEndpoint -Name "POST /products/warehouses" -Url "http://localhost:8081/warehouses" -Method "POST" -Body $warehouse
$testResults += @{ Test = "Crear Almacen"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 5: Crear Usuario
Write-Host ""
Write-ColorOutput "=== TEST 5: Crear Usuario ===" "Cyan"
$user = @{
    username = "admin"
    password = "admin123"
    fullName = "Administrador Sistema"
    email = "admin@azulejosromu.com"
    role = "ADMIN"
}
$result = Test-ApiEndpoint -Name "POST /users/users" -Url "http://localhost:8084/users" -Method "POST" -Body $user
$testResults += @{ Test = "Crear Usuario"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 6: Login
Write-Host ""
Write-ColorOutput "=== TEST 6: Login de Usuario ===" "Cyan"
$credentials = @{
    username = "admin"
    password = "admin123"
}
$result = Test-ApiEndpoint -Name "POST /users/auth/login" -Url "http://localhost:8084/auth/login" -Method "POST" -Body $credentials
$testResults += @{ Test = "Login Usuario"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 7: Crear Camion
Write-Host ""
Write-ColorOutput "=== TEST 7: Crear Camion ===" "Cyan"
$truck = @{
    licensePlate = "1234ABC"
    brand = "Mercedes"
    model = "Actros"
    year = 2022
    status = "DISPONIBLE"
}
$result = Test-ApiEndpoint -Name "POST /logistics/trucks" -Url "http://localhost:8083/trucks" -Method "POST" -Body $truck
$testResults += @{ Test = "Crear Camion"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 8: Verificar Eureka
Write-Host ""
Write-ColorOutput "=== TEST 8: Servicios Registrados en Eureka ===" "Cyan"
$result = Test-ApiEndpoint -Name "GET Eureka Applications" -Url "http://localhost:8761/eureka/apps"
$testResults += @{ Test = "Eureka Registry"; Result = $result }

# ==========================================
# RESUMEN DE PRUEBAS
# ==========================================

Write-Host ""
Write-Header "RESUMEN DE PRUEBAS"

$passed = ($testResults | Where-Object { $_.Result -eq $true }).Count
$failed = ($testResults | Where-Object { $_.Result -eq $false }).Count
$total = $testResults.Count

foreach ($test in $testResults) {
    if ($test.Result) {
        Write-Success $test.Test
    } else {
        Write-Error $test.Test
    }
}

Write-Host ""
Write-ColorOutput "====================================" "Cyan"
Write-ColorOutput "Total de pruebas: $total" "White"
Write-ColorOutput "Exitosas: $passed" "Green"
Write-ColorOutput "Fallidas: $failed" "Red"
Write-ColorOutput "====================================" "Cyan"

# ==========================================
# INFORMACION DE URLS Y COMANDOS
# ==========================================

Write-Host ""
Write-Header "URLs DE LOS SERVICIOS"

Write-ColorOutput "Eureka Dashboard:      http://localhost:8761" "Yellow"
Write-ColorOutput "Gateway:               http://localhost:8080" "Yellow"
Write-ColorOutput "Products Service:      http://localhost:8081" "Yellow"
Write-ColorOutput "Orders Service:        http://localhost:8082" "Yellow"
Write-ColorOutput "Logistics Service:     http://localhost:8083" "Yellow"
Write-ColorOutput "Users Service:         http://localhost:8084" "Yellow"

Write-Host ""
Write-ColorOutput "=== Swagger UI ===" "Cyan"
Write-ColorOutput "Products:  http://localhost:8081/swagger-ui/index.html" "Yellow"
Write-ColorOutput "Orders:    http://localhost:8082/swagger-ui/index.html" "Yellow"
Write-ColorOutput "Logistics: http://localhost:8083/swagger-ui/index.html" "Yellow"
Write-ColorOutput "Users:     http://localhost:8084/swagger-ui/index.html" "Yellow"

Write-Host ""
Write-Header "COMANDOS UTILES DE DOCKER"

Write-ColorOutput "Ver logs de todos los servicios:" "Cyan"
Write-Host "  docker compose logs -f" -ForegroundColor Gray

Write-ColorOutput "Ver logs de un servicio especifico:" "Cyan"
Write-Host "  docker compose logs -f products-service" -ForegroundColor Gray

Write-ColorOutput "Detener todos los servicios:" "Cyan"
Write-Host "  docker compose down" -ForegroundColor Gray

Write-ColorOutput "Detener y eliminar volumenes:" "Cyan"
Write-Host "  docker compose down -v" -ForegroundColor Gray

Write-ColorOutput "Ver estado de contenedores:" "Cyan"
Write-Host "  docker compose ps" -ForegroundColor Gray

Write-Host ""
Write-Success "Script de pruebas completado!"
Write-Info "Los servicios estan ejecutandose en contenedores Docker"
Write-Info "Para detenerlos ejecuta: docker compose down"

Write-Host ""
