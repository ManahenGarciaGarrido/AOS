package com.azulejosromu.users_service.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "warehouse_assignments",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "warehouse_id"}))
@Data
public class WarehouseAssignment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "warehouse_id", nullable = false)
    private Long warehouseId;

    @Column(name = "is_primary")
    private Boolean isPrimary = false;

    private Boolean active = true;

    @Column(name = "assigned_at")
    private LocalDateTime assignedAt = LocalDateTime.now();

    @Column(name = "assigned_by")
    private Long assignedBy;

    @Column(columnDefinition = "TEXT")
    private String notes;
}
