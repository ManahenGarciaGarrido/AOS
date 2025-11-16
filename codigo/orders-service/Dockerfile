# Multistage build para Orders Service
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copiar pom.xml primero para aprovechar cache de Docker
COPY pom.xml .

# Copiar código fuente y construir
COPY src ./src
RUN mvn clean package -DskipTests

# Imagen final ligera
FROM eclipse-temurin:21-jre-alpine

# Instalar wget para healthcheck
RUN apk add --no-cache wget

WORKDIR /app

# Copiar JAR desde la etapa de build
COPY --from=build /app/target/*.jar app.jar

# Exponer puerto
EXPOSE 8082

# Healthcheck
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=60s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8082/actuator/health || exit 1

# Ejecutar aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]
