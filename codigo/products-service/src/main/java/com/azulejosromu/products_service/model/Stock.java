package com.azulejosromu.products_service.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "stock",
       uniqueConstraints = @UniqueConstraint(columnNames = {"product_id", "warehouse_id"}))
@Data
public class Stock {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "product_id", nullable = false)
    private Long productId;

    @Column(name = "warehouse_id", nullable = false)
    private Long warehouseId;

    @Column(nullable = false)
    private Integer quantity = 0;

    @Column(name = "min_stock")
    private Integer minStock = 0;

    @Column(name = "max_stock")
    private Integer maxStock = 1000;

    @Column(name = "reorder_point")
    private Integer reorderPoint = 10;

    @Column(length = 50)
    private String location;

    @Column(name = "last_stock_check")
    private LocalDateTime lastStockCheck;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();
}
