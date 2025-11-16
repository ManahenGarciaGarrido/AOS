package com.azulejosromu.orders_service.model;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "orders")
@Data
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 50)
    private String orderNumber;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private OrderType orderType;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private OrderStatus status = OrderStatus.PENDIENTE;

    @Column(name = "customer_id")
    private Long customerId;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "warehouse_id", nullable = false)
    private Long warehouseId;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmount = BigDecimal.ZERO;

    @Column(precision = 10, scale = 2)
    private BigDecimal tax = BigDecimal.ZERO;

    @Column(precision = 10, scale = 2)
    private BigDecimal shipping = BigDecimal.ZERO;

    @Column(columnDefinition = "TEXT")
    private String deliveryAddress;

    @Column(length = 100)
    private String deliveryCity;

    @Column(length = 20)
    private String deliveryPostalCode;

    @Column(precision = 10, scale = 7)
    private BigDecimal deliveryLatitude;

    @Column(precision = 10, scale = 7)
    private BigDecimal deliveryLongitude;

    @Column(name = "delivery_date")
    private LocalDateTime deliveryDate;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items;

    public enum OrderType {
        CLIENTE,
        REPOSICION,
        PROVEEDOR
    }

    public enum OrderStatus {
        PENDIENTE,
        CONFIRMADO,
        EN_PREPARACION,
        LISTO_ENVIO,
        EN_RUTA,
        ENTREGADO,
        CANCELADO
    }
}
