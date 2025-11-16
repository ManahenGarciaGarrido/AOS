package com.azulejosromu.logistics_service.model;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "routes")
@Data
public class Route {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 50)
    private String routeCode;

    @Column(name = "truck_id", nullable = false)
    private Long truckId;

    @Column(name = "driver_id", nullable = false)
    private Long driverId;

    @Column(length = 20)
    @Enumerated(EnumType.STRING)
    private RouteStatus status = RouteStatus.PLANIFICADA;

    @Column(name = "scheduled_start")
    private LocalDateTime scheduledStart;

    @Column(name = "scheduled_end")
    private LocalDateTime scheduledEnd;

    @Column(name = "actual_start")
    private LocalDateTime actualStart;

    @Column(name = "actual_end")
    private LocalDateTime actualEnd;

    @Column(precision = 10, scale = 2)
    private BigDecimal totalDistanceKm;

    @Column(precision = 10, scale = 2)
    private BigDecimal estimatedDurationHours;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @OneToMany(mappedBy = "route", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RouteStop> stops;

    public enum RouteStatus {
        PLANIFICADA,
        EN_CURSO,
        COMPLETADA,
        CANCELADA
    }
}
