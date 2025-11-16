# ==========================================
# Script de Prueba de Microservicios
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
    Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║  $Title" "Cyan"
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" "Yellow"
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxRetries = 30,
        [int]$DelaySeconds = 2
    )

    Write-Info "Verificando $ServiceName en $Url..."

    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Success "$ServiceName está funcionando! (Intento $i/$MaxRetries)"
                return $true
            }
        }
        catch {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    Write-Error "$ServiceName no responde después de $MaxRetries intentos"
    return $false
}

function Start-Service {
    param(
        [string]$ServiceName,
        [string]$Path,
        [int]$Port
    )

    Write-Info "Iniciando $ServiceName en puerto $Port..."

    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Path'; Write-Host 'Iniciando $ServiceName...' -ForegroundColor Cyan; mvn spring-boot:run" -WindowStyle Normal

    Start-Sleep -Seconds 3
    Write-Success "$ServiceName iniciado (ventana separada)"
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
            $jsonBody = $Body | ConvertTo-Json
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
        Write-Error "Error en la petición: $($_.Exception.Message)"
        return $false
    }
}

# ==========================================
# INICIO DEL SCRIPT
# ==========================================

Clear-Host
Write-Header "SISTEMA DE MICROSERVICIOS - AZULEJOS ROMU"
Write-ColorOutput "Autor: Script de Pruebas Automatizado" "Cyan"
$fechaActual = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-ColorOutput "Fecha: $fechaActual" "Cyan"
Write-Host ""

Write-ColorOutput "Este script realizará las siguientes acciones:" "Yellow"
Write-Host "  1. Iniciar todos los microservicios en ventanas separadas" -ForegroundColor Gray
Write-Host "  2. Verificar que cada servicio esté funcionando" -ForegroundColor Gray
Write-Host "  3. Ejecutar pruebas de endpoints" -ForegroundColor Gray
Write-Host "  4. Mostrar resultados de forma visual" -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "¿Desea continuar? (S/N)"
if ($continue -ne "S" -and $continue -ne "s") {
    Write-Info "Script cancelado por el usuario"
    exit
}

$projectRoot = $PSScriptRoot

# ==========================================
# FASE 1: SERVICIOS DE INFRAESTRUCTURA
# ==========================================

Write-Header "FASE 1: Iniciando Servicios de Infraestructura"

# Eureka Server
Start-Service -ServiceName "Eureka Server" -Path "$projectRoot\codigo\eureka-server" -Port 8761
Write-Host ""

# Esperar a que Eureka esté listo
if (-not (Test-ServiceHealth -ServiceName "Eureka Server" -Url "http://localhost:8761")) {
    Write-Error "No se pudo iniciar Eureka Server. Abortando..."
    exit 1
}

Write-Host ""
Start-Sleep -Seconds 5

# Config Server
Start-Service -ServiceName "Config Server" -Path "$projectRoot\codigo\config-server" -Port 8888
Write-Host ""

if (-not (Test-ServiceHealth -ServiceName "Config Server" -Url "http://localhost:8888/actuator/health")) {
    Write-Error "No se pudo iniciar Config Server. Abortando..."
    exit 1
}

Write-Host ""
Write-Success "Servicios de infraestructura iniciados correctamente"
Start-Sleep -Seconds 10

# ==========================================
# FASE 2: MICROSERVICIOS DE NEGOCIO
# ==========================================

Write-Header "FASE 2: Iniciando Microservicios de Negocio"

# Products Service
Start-Service -ServiceName "Products Service" -Path "$projectRoot\codigo\products-service" -Port 8081
Write-Host ""
Start-Sleep -Seconds 15

if (-not (Test-ServiceHealth -ServiceName "Products Service" -Url "http://localhost:8081/actuator/health" -MaxRetries 40)) {
    Write-Error "Products Service no responde, pero continuamos..."
}

# Orders Service
Start-Service -ServiceName "Orders Service" -Path "$projectRoot\codigo\orders-service" -Port 8091
Write-Host ""
Start-Sleep -Seconds 15

if (-not (Test-ServiceHealth -ServiceName "Orders Service" -Url "http://localhost:8091/actuator/health" -MaxRetries 40)) {
    Write-Error "Orders Service no responde, pero continuamos..."
}

# Logistics Service
Start-Service -ServiceName "Logistics Service" -Path "$projectRoot\codigo\logistics-service" -Port 8101
Write-Host ""
Start-Sleep -Seconds 15

if (-not (Test-ServiceHealth -ServiceName "Logistics Service" -Url "http://localhost:8101/actuator/health" -MaxRetries 40)) {
    Write-Error "Logistics Service no responde, pero continuamos..."
}

# Users Service
Start-Service -ServiceName "Users Service" -Path "$projectRoot\codigo\users-service" -Port 8111
Write-Host ""
Start-Sleep -Seconds 15

if (-not (Test-ServiceHealth -ServiceName "Users Service" -Url "http://localhost:8111/actuator/health" -MaxRetries 40)) {
    Write-Error "Users Service no responde, pero continuamos..."
}

# Gateway Service
Start-Service -ServiceName "Gateway Service" -Path "$projectRoot\codigo\gateway-service" -Port 8080
Write-Host ""
Start-Sleep -Seconds 15

if (-not (Test-ServiceHealth -ServiceName "Gateway Service" -Url "http://localhost:8080/actuator/health" -MaxRetries 40)) {
    Write-Error "Gateway Service no responde, pero continuamos..."
}

Write-Host ""
Write-Success "Todos los microservicios han sido iniciados"
Write-Info "Esperando 20 segundos para que todos los servicios se registren en Eureka..."
Start-Sleep -Seconds 20

# ==========================================
# FASE 3: PRUEBAS DE ENDPOINTS
# ==========================================

Write-Header "FASE 3: Ejecutando Pruebas de Endpoints"

$testResults = @()

# Prueba 1: Crear Categoría
Write-Host ""
Write-ColorOutput "═══ TEST 1: Crear Categoría ═══" "Cyan"
$category = @{
    code = "AZUL001"
    name = "Azulejos Baño"
    description = "Azulejos para baño"
}
$result = Test-ApiEndpoint -Name "POST /products/categories" -Url "http://localhost:8081/categories" -Method "POST" -Body $category
$testResults += @{ Test = "Crear Categoría"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 2: Listar Categorías
Write-Host ""
Write-ColorOutput "═══ TEST 2: Listar Categorías ═══" "Cyan"
$result = Test-ApiEndpoint -Name "GET /products/categories" -Url "http://localhost:8081/categories"
$testResults += @{ Test = "Listar Categorías"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 3: Crear Proveedor
Write-Host ""
Write-ColorOutput "═══ TEST 3: Crear Proveedor ═══" "Cyan"
$supplier = @{
    name = "Cerámicas Romu S.L."
    nif = "B12345678"
    city = "Valencia"
    country = "España"
    phone = "+34 960 000 000"
    email = "contacto@ceramicasromu.com"
}
$result = Test-ApiEndpoint -Name "POST /products/suppliers" -Url "http://localhost:8081/suppliers" -Method "POST" -Body $supplier
$testResults += @{ Test = "Crear Proveedor"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 4: Crear Almacén
Write-Host ""
Write-ColorOutput "═══ TEST 4: Crear Almacén ═══" "Cyan"
$warehouse = @{
    code = "ALM001"
    name = "Almacén Central Valencia"
    city = "Valencia"
    latitude = 39.4699
    longitude = -0.3763
}
$result = Test-ApiEndpoint -Name "POST /products/warehouses" -Url "http://localhost:8081/warehouses" -Method "POST" -Body $warehouse
$testResults += @{ Test = "Crear Almacén"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 5: Crear Usuario
Write-Host ""
Write-ColorOutput "═══ TEST 5: Crear Usuario ═══" "Cyan"
$user = @{
    username = "admin"
    password = "admin123"
    fullName = "Administrador Sistema"
    email = "admin@azulejosromu.com"
    role = "ADMIN"
}
$result = Test-ApiEndpoint -Name "POST /users/users" -Url "http://localhost:8111/users" -Method "POST" -Body $user
$testResults += @{ Test = "Crear Usuario"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 6: Login
Write-Host ""
Write-ColorOutput "═══ TEST 6: Login de Usuario ═══" "Cyan"
$credentials = @{
    username = "admin"
    password = "admin123"
}
$result = Test-ApiEndpoint -Name "POST /users/auth/login" -Url "http://localhost:8111/auth/login" -Method "POST" -Body $credentials
$testResults += @{ Test = "Login Usuario"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 7: Crear Camión
Write-Host ""
Write-ColorOutput "═══ TEST 7: Crear Camión ═══" "Cyan"
$truck = @{
    licensePlate = "1234ABC"
    brand = "Mercedes"
    model = "Actros"
    year = 2022
    status = "DISPONIBLE"
}
$result = Test-ApiEndpoint -Name "POST /logistics/trucks" -Url "http://localhost:8101/trucks" -Method "POST" -Body $truck
$testResults += @{ Test = "Crear Camión"; Result = $result }

Start-Sleep -Seconds 2

# Prueba 8: Verificar Eureka
Write-Host ""
Write-ColorOutput "═══ TEST 8: Servicios Registrados en Eureka ═══" "Cyan"
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
Write-ColorOutput "════════════════════════════════════" "Cyan"
Write-ColorOutput "Total de pruebas: $total" "White"
Write-ColorOutput "Exitosas: $passed" "Green"
Write-ColorOutput "Fallidas: $failed" "Red"
Write-ColorOutput "════════════════════════════════════" "Cyan"

# ==========================================
# INFORMACIÓN DE URLS
# ==========================================

Write-Host ""
Write-Header "URLs DE LOS SERVICIOS"

Write-ColorOutput "Eureka Dashboard:      http://localhost:8761" "Yellow"
Write-ColorOutput "Gateway:               http://localhost:8080" "Yellow"
Write-ColorOutput "Products Service:      http://localhost:8081" "Yellow"
Write-ColorOutput "Orders Service:        http://localhost:8091" "Yellow"
Write-ColorOutput "Logistics Service:     http://localhost:8101" "Yellow"
Write-ColorOutput "Users Service:         http://localhost:8111" "Yellow"

Write-Host ""
Write-ColorOutput "═══ Swagger UI ═══" "Cyan"
Write-ColorOutput "Products:  http://localhost:8081/swagger-ui/index.html" "Yellow"
Write-ColorOutput "Orders:    http://localhost:8091/swagger-ui/index.html" "Yellow"
Write-ColorOutput "Logistics: http://localhost:8101/swagger-ui/index.html" "Yellow"
Write-ColorOutput "Users:     http://localhost:8111/swagger-ui/index.html" "Yellow"

Write-Host ""
Write-Success "Script de pruebas completado!"
Write-Info "Los servicios seguirán ejecutándose en las ventanas abiertas"
Write-Info "Cierra las ventanas manualmente cuando quieras detener los servicios"

Write-Host ""
