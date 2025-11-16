package com.azulejosromu.logistics_service.model;

import jakarta.persistence.*;
import lombok.Data;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "route_stops")
@Data
public class RouteStop {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_id", nullable = false)
    @JsonIgnore
    private Route route;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "stop_sequence", nullable = false)
    private Integer stopSequence;

    @Column(precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(name = "estimated_arrival")
    private LocalDateTime estimatedArrival;

    @Column(name = "actual_arrival")
    private LocalDateTime actualArrival;

    @Column(name = "estimated_departure")
    private LocalDateTime estimatedDeparture;

    @Column(name = "actual_departure")
    private LocalDateTime actualDeparture;

    @Column(length = 20)
    @Enumerated(EnumType.STRING)
    private StopStatus status = StopStatus.PENDIENTE;

    @Column(columnDefinition = "TEXT")
    private String notes;

    public enum StopStatus {
        PENDIENTE,
        EN_CAMINO,
        LLEGADO,
        COMPLETADO,
        FALLIDO
    }
}
