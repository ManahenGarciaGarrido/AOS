# ==========================================
# Script de Prueba de Microservicios con Docker
# Azulejos Romu - Windows PowerShell
# Prueba completa de los 18 Casos de Uso
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
        [string]$CaseNumber,
        [string]$CaseName,
        [string]$Url,
        [string]$Method = "GET",
        [object]$Body = $null
    )

    Write-Host ""
    Write-ColorOutput "=== $CaseNumber: $CaseName ===" "Cyan"
    Write-Host "   URL: $Url" -ForegroundColor Gray
    Write-Host "   Method: $Method" -ForegroundColor Gray

    try {
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            Write-Host "   Body: $jsonBody" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Body $jsonBody -ContentType "application/json" -ErrorAction Stop
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -ErrorAction Stop
        }

        Write-Success "Caso de uso completado exitosamente"

        if ($response -is [System.Array]) {
            Write-Host "   Resultado: $($response.Count) elementos" -ForegroundColor Magenta
        } elseif ($response -is [PSCustomObject]) {
            Write-Host "   Resultado: Objeto JSON" -ForegroundColor Magenta
        } else {
            Write-Host "   Resultado: $response" -ForegroundColor Magenta
        }

        return @{ Case = $CaseNumber; Name = $CaseName; Result = $true }
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
        return @{ Case = $CaseNumber; Name = $CaseName; Result = $false }
    }
}

# ==========================================
# INICIO DEL SCRIPT
# ==========================================

Clear-Host
Write-Header "SISTEMA DE MICROSERVICIOS - AZULEJOS ROMU"
Write-ColorOutput "Prueba Completa de los 18 Casos de Uso" "Cyan"
$fechaActual = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-ColorOutput "Fecha: $fechaActual" "Cyan"
Write-Host ""

Write-ColorOutput "Este script realizara las siguientes acciones:" "Yellow"
Write-Host "  1. Verificar que Docker este instalado y funcionando" -ForegroundColor Gray
Write-Host "  2. Construir y levantar todos los contenedores" -ForegroundColor Gray
Write-Host "  3. Verificar que cada servicio este funcionando" -ForegroundColor Gray
Write-Host "  4. Ejecutar pruebas de los 18 casos de uso" -ForegroundColor Gray
Write-Host "  5. Mostrar resultados finales" -ForegroundColor Gray
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
Write-Header "CONSTRUYENDO Y LEVANTANDO SERVICIOS"

Write-Info "Iniciando construccion de imagenes..."
Write-ColorOutput "NOTA: La primera vez puede tardar varios minutos..." "Yellow"
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
docker compose ps

# ==========================================
# VERIFICAR SALUD DE SERVICIOS
# ==========================================

Write-Host ""
Write-Header "VERIFICANDO SALUD DE SERVICIOS"

$healthChecks = @(
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
    if (-not (Test-ServiceHealth -ServiceName $check.Name -Url $check.Url)) {
        $allHealthy = $false
    }
    Write-Host ""
}

if (-not $allHealthy) {
    Write-Error "Algunos servicios no estan respondiendo"
    Write-Info "Verifica los logs con: docker compose logs [servicio]"
}

Write-Info "Esperando 15 segundos para que los servicios se registren en Eureka..."
Start-Sleep -Seconds 15

# ==========================================
# PRUEBAS DE LOS 18 CASOS DE USO
# ==========================================

Write-Header "EJECUTANDO PRUEBAS DE LOS 18 CASOS DE USO"

$testResults = @()

# =========================================
# BC-1: GESTION DE PRODUCTOS Y STOCK
# =========================================

Write-ColorOutput "`n*** BC-1: GESTION DE PRODUCTOS Y STOCK ***" "Magenta"

# CU-01: Mantener Catálogo de Productos
$category = @{
    code = "AZUL001"
    name = "Azulejos Bano"
    description = "Azulejos para bano"
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-01" -CaseName "Mantener Catalogo de Productos - Crear Categoria" -Url "http://localhost:8081/categories" -Method "POST" -Body $category
Start-Sleep -Seconds 1

$supplier = @{
    name = "Ceramicas Romu S.L."
    nif = "B12345678"
    city = "Valencia"
    country = "Espana"
    phone = "+34 960 000 000"
    email = "contacto@ceramicasromu.com"
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-01" -CaseName "Mantener Catalogo de Productos - Crear Producto" -Url "http://localhost:8081/suppliers" -Method "POST" -Body $supplier
Start-Sleep -Seconds 1

# CU-02: Gestionar Proveedores
$testResults += Test-ApiEndpoint -CaseNumber "CU-02" -CaseName "Gestionar Proveedores - Listar Proveedores" -Url "http://localhost:8081/suppliers" -Method "GET"
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-02" -CaseName "Gestionar Proveedores - Buscar por NIF" -Url "http://localhost:8081/suppliers/nif/B12345678" -Method "GET"
Start-Sleep -Seconds 1

# CU-03: Consultar Stock Disponible
$warehouse = @{
    code = "ALM001"
    name = "Almacen Central"
    city = "Valencia"
    latitude = 39.4699
    longitude = -0.3763
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-03" -CaseName "Consultar Stock Disponible - Crear Almacen" -Url "http://localhost:8081/warehouses" -Method "POST" -Body $warehouse
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-03" -CaseName "Consultar Stock Disponible - Listar Stock" -Url "http://localhost:8081/stock" -Method "GET"
Start-Sleep -Seconds 1

# CU-04: Controlar Movimientos de Stock
$stockAdjustment = @{
    productId = 1
    warehouseId = 1
    quantity = 100
    movementType = "IN"
    notes = "Entrada inicial de stock"
    userId = 1
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-04" -CaseName "Controlar Movimientos de Stock - Ajustar Stock" -Url "http://localhost:8081/stock/adjust" -Method "POST" -Body $stockAdjustment
Start-Sleep -Seconds 1

# CU-05: Generar Alertas de Reposición
$testResults += Test-ApiEndpoint -CaseNumber "CU-05" -CaseName "Generar Alertas de Reposicion - Stock Bajo" -Url "http://localhost:8081/stock/low-stock" -Method "GET"
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-05" -CaseName "Generar Alertas de Reposicion - Productos a Reponer" -Url "http://localhost:8081/stock/reorder" -Method "GET"
Start-Sleep -Seconds 1

# =========================================
# BC-2: GESTION DE PEDIDOS
# =========================================

Write-ColorOutput "`n*** BC-2: GESTION DE PEDIDOS ***" "Magenta"

# CU-06: Realizar Pedido de Cliente
$customerOrder = @{
    orderNumber = "ORD-2025-001"
    orderType = "CUSTOMER"
    customerId = 1
    status = "PENDING"
    deliveryType = "HOME"
    deliveryAddress = "Calle Mayor 25, Plasencia"
    deliveryCity = "Plasencia"
    totalAmount = 775.00
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-06" -CaseName "Realizar Pedido de Cliente" -Url "http://localhost:8082/orders" -Method "POST" -Body $customerOrder
Start-Sleep -Seconds 1

# CU-07: Gestionar Pedido de Reposición
$replenishmentOrder = @{
    orderNumber = "ORD-2025-002"
    orderType = "REPLENISHMENT"
    warehouseId = 1
    status = "PENDING"
    totalAmount = 1500.00
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-07" -CaseName "Gestionar Pedido de Reposicion" -Url "http://localhost:8082/orders" -Method "POST" -Body $replenishmentOrder
Start-Sleep -Seconds 1

# CU-08: Gestionar Pedido a Proveedor
$supplierOrder = @{
    orderNumber = "ORD-2025-003"
    orderType = "SUPPLIER"
    supplierId = 1
    status = "PENDING"
    totalAmount = 5000.00
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-08" -CaseName "Gestionar Pedido a Proveedor" -Url "http://localhost:8082/orders" -Method "POST" -Body $supplierOrder
Start-Sleep -Seconds 1

# CU-09: Actualizar Estado de Pedido
$statusUpdate = @{
    status = "PREPARING"
    userId = 1
    notes = "Pedido en preparacion"
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-09" -CaseName "Actualizar Estado de Pedido" -Url "http://localhost:8082/orders/1/status" -Method "PUT" -Body $statusUpdate
Start-Sleep -Seconds 1

# CU-10: Consultar Historial de Pedidos
$testResults += Test-ApiEndpoint -CaseNumber "CU-10" -CaseName "Consultar Historial de Pedidos - Listar Todos" -Url "http://localhost:8082/orders" -Method "GET"
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-10" -CaseName "Consultar Historial de Pedidos - Por Tipo" -Url "http://localhost:8082/orders/type/CUSTOMER" -Method "GET"
Start-Sleep -Seconds 1

# =========================================
# BC-3: LOGISTICA Y DISTRIBUCION
# =========================================

Write-ColorOutput "`n*** BC-3: LOGISTICA Y DISTRIBUCION ***" "Magenta"

# CU-11: Gestionar Flota de Camiones
$truck = @{
    licensePlate = "1234ABC"
    brand = "Mercedes"
    model = "Actros"
    year = 2022
    status = "DISPONIBLE"
    loadCapacityKg = 12000
    volumeCapacitym3 = 40
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-11" -CaseName "Gestionar Flota de Camiones - Crear Camion" -Url "http://localhost:8083/trucks" -Method "POST" -Body $truck
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-11" -CaseName "Gestionar Flota de Camiones - Listar Camiones" -Url "http://localhost:8083/trucks" -Method "GET"
Start-Sleep -Seconds 1

# CU-12: Optimizar Rutas de Entrega
$driver = @{
    name = "Juan Perez"
    nif = "12345678A"
    licenseNumber = "B1234567"
    status = "DISPONIBLE"
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-12" -CaseName "Optimizar Rutas de Entrega - Crear Conductor" -Url "http://localhost:8083/drivers" -Method "POST" -Body $driver
Start-Sleep -Seconds 1

$routeOptimization = @{
    truckId = 1
    driverId = 1
    orderIds = @(1, 2, 3)
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-12" -CaseName "Optimizar Rutas de Entrega - Optimizar Ruta" -Url "http://localhost:8083/routes/optimize" -Method "POST" -Body $routeOptimization
Start-Sleep -Seconds 1

# CU-13: Seguimiento GPS en Tiempo Real
$gpsTracking = @{
    truckId = 1
    routeId = 1
    latitude = 40.0381
    longitude = -6.0893
    speed = 65.5
    heading = 180.0
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-13" -CaseName "Seguimiento GPS en Tiempo Real - Registrar Posicion" -Url "http://localhost:8083/tracking" -Method "POST" -Body $gpsTracking
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-13" -CaseName "Seguimiento GPS en Tiempo Real - Obtener Ultima Posicion" -Url "http://localhost:8083/tracking/truck/1/latest" -Method "GET"
Start-Sleep -Seconds 1

# CU-14: Asignar Entregas a Repartidores
$testResults += Test-ApiEndpoint -CaseNumber "CU-14" -CaseName "Asignar Entregas a Repartidores - Ver Rutas del Conductor" -Url "http://localhost:8083/routes/driver/1" -Method "GET"
Start-Sleep -Seconds 1

# =========================================
# BC-4: GESTION DE USUARIOS Y SEGURIDAD
# =========================================

Write-ColorOutput "`n*** BC-4: GESTION DE USUARIOS Y SEGURIDAD ***" "Magenta"

# CU-15: Autenticar Usuario
$user = @{
    username = "admin"
    password = "admin123"
    fullName = "Administrador Sistema"
    email = "admin@azulejosromu.com"
    role = "ADMIN"
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-15" -CaseName "Autenticar Usuario - Crear Usuario" -Url "http://localhost:8084/users" -Method "POST" -Body $user
Start-Sleep -Seconds 1

$credentials = @{
    username = "admin"
    password = "admin123"
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-15" -CaseName "Autenticar Usuario - Login" -Url "http://localhost:8084/auth/login" -Method "POST" -Body $credentials
Start-Sleep -Seconds 1

# CU-16: Gestionar Roles y Permisos
$testResults += Test-ApiEndpoint -CaseNumber "CU-16" -CaseName "Gestionar Roles y Permisos - Listar Usuarios" -Url "http://localhost:8084/users" -Method "GET"
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-16" -CaseName "Gestionar Roles y Permisos - Buscar por Rol" -Url "http://localhost:8084/users/role/ADMIN" -Method "GET"
Start-Sleep -Seconds 1

# CU-17: Asignar Mozos a Almacenes
$warehouseAssignment = @{
    userId = 1
    warehouseId = 1
    assignmentDate = (Get-Date -Format "yyyy-MM-dd")
    isCurrent = $true
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-17" -CaseName "Asignar Mozos a Almacenes - Crear Asignacion" -Url "http://localhost:8084/warehouse-assignments" -Method "POST" -Body $warehouseAssignment
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-17" -CaseName "Asignar Mozos a Almacenes - Ver Asignaciones Actuales" -Url "http://localhost:8084/warehouse-assignments/user/1/current" -Method "GET"
Start-Sleep -Seconds 1

# CU-18: Auditar Operaciones
$auditLog = @{
    userId = 1
    action = "CREATE_ORDER"
    entityType = "ORDER"
    entityId = 1
    details = "Pedido creado por el usuario admin"
}
$testResults += Test-ApiEndpoint -CaseNumber "CU-18" -CaseName "Auditar Operaciones - Registrar Evento" -Url "http://localhost:8084/audit-logs" -Method "POST" -Body $auditLog
Start-Sleep -Seconds 1

$testResults += Test-ApiEndpoint -CaseNumber "CU-18" -CaseName "Auditar Operaciones - Consultar Auditoria de Usuario" -Url "http://localhost:8084/audit-logs/user/1" -Method "GET"
Start-Sleep -Seconds 1

# ==========================================
# RESUMEN DE PRUEBAS
# ==========================================

Write-Host ""
Write-Header "RESUMEN DE PRUEBAS DE LOS 18 CASOS DE USO"

$passed = ($testResults | Where-Object { $_.Result -eq $true }).Count
$failed = ($testResults | Where-Object { $_.Result -eq $false }).Count
$total = $testResults.Count

Write-ColorOutput "`nCasos de Uso por Business Capability:" "Cyan"

# Agrupar por BC
Write-ColorOutput "`nBC-1: GESTION DE PRODUCTOS Y STOCK" "Yellow"
$testResults | Where-Object { $_.Case -match "CU-0[1-5]" } | ForEach-Object {
    if ($_.Result) {
        Write-Success "$($_.Case): $($_.Name)"
    } else {
        Write-Error "$($_.Case): $($_.Name)"
    }
}

Write-ColorOutput "`nBC-2: GESTION DE PEDIDOS" "Yellow"
$testResults | Where-Object { $_.Case -match "CU-(06|07|08|09|10)" } | ForEach-Object {
    if ($_.Result) {
        Write-Success "$($_.Case): $($_.Name)"
    } else {
        Write-Error "$($_.Case): $($_.Name)"
    }
}

Write-ColorOutput "`nBC-3: LOGISTICA Y DISTRIBUCION" "Yellow"
$testResults | Where-Object { $_.Case -match "CU-1[1-4]" } | ForEach-Object {
    if ($_.Result) {
        Write-Success "$($_.Case): $($_.Name)"
    } else {
        Write-Error "$($_.Case): $($_.Name)"
    }
}

Write-ColorOutput "`nBC-4: GESTION DE USUARIOS Y SEGURIDAD" "Yellow"
$testResults | Where-Object { $_.Case -match "CU-1[5-8]" } | ForEach-Object {
    if ($_.Result) {
        Write-Success "$($_.Case): $($_.Name)"
    } else {
        Write-Error "$($_.Case): $($_.Name)"
    }
}

Write-Host ""
Write-ColorOutput "====================================" "Cyan"
Write-ColorOutput "Total de pruebas: $total" "White"
Write-ColorOutput "Exitosas: $passed" "Green"
Write-ColorOutput "Fallidas: $failed" "Red"
$percentage = [math]::Round(($passed / $total) * 100, 2)
Write-ColorOutput "Porcentaje de exito: $percentage%" "White"
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
if ($failed -eq 0) {
    Write-Success "Todos los casos de uso pasaron las pruebas!"
} else {
    Write-ColorOutput "Algunos casos de uso fallaron. Revisa los logs para mas detalles." "Red"
}
Write-Info "Los servicios estan ejecutandose en contenedores Docker"
Write-Info "Para detenerlos ejecuta: docker compose down"

Write-Host ""
