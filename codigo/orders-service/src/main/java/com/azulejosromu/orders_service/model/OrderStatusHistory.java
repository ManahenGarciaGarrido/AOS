package com.azulejosromu.orders_service.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "order_status_history")
@Data
public class OrderStatusHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private Order.OrderStatus previousStatus;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private Order.OrderStatus newStatus;

    @Column(name = "changed_by")
    private Long changedBy;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "changed_at")
    private LocalDateTime changedAt = LocalDateTime.now();
}
