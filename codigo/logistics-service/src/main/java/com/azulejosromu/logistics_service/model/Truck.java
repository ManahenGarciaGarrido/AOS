package com.azulejosromu.logistics_service.model;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "trucks")
@Data
public class Truck {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 50)
    private String licensePlate;

    @Column(length = 100)
    private String brand;

    @Column(length = 100)
    private String model;

    private Integer year;

    @Column(precision = 10, scale = 2)
    private BigDecimal loadCapacityKg;

    @Column(precision = 10, scale = 2)
    private BigDecimal volumeCapacityM3;

    @Column(length = 20)
    @Enumerated(EnumType.STRING)
    private TruckStatus status = TruckStatus.DISPONIBLE;

    @Column(name = "last_maintenance")
    private LocalDateTime lastMaintenance;

    @Column(name = "next_maintenance")
    private LocalDateTime nextMaintenance;

    private BigDecimal odometer;

    private Boolean active = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    public enum TruckStatus {
        DISPONIBLE,
        EN_RUTA,
        MANTENIMIENTO,
        FUERA_SERVICIO
    }
}
