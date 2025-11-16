-- Script de inicialización para crear las bases de datos de Azulejos Romu
-- Este script se ejecuta automáticamente cuando el contenedor MySQL se inicia por primera vez

-- Crear base de datos para Products Service
CREATE DATABASE IF NOT EXISTS products_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear base de datos para Orders Service
CREATE DATABASE IF NOT EXISTS orders_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear base de datos para Logistics Service
CREATE DATABASE IF NOT EXISTS logistics_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear base de datos para Users Service
CREATE DATABASE IF NOT EXISTS users_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Otorgar todos los privilegios al usuario 'azulejos' en todas las bases de datos
GRANT ALL PRIVILEGES ON products_db.* TO 'azulejos'@'%';
GRANT ALL PRIVILEGES ON orders_db.* TO 'azulejos'@'%';
GRANT ALL PRIVILEGES ON logistics_db.* TO 'azulejos'@'%';
GRANT ALL PRIVILEGES ON users_db.* TO 'azulejos'@'%';

FLUSH PRIVILEGES;

-- Mostrar las bases de datos creadas
SHOW DATABASES;
