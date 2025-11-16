package com.azulejosromu.users_service.repository;

import com.azulejosromu.users_service.model.WarehouseAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WarehouseAssignmentRepository extends JpaRepository<WarehouseAssignment, Long> {
    List<WarehouseAssignment> findByUserId(Long userId);
    List<WarehouseAssignment> findByWarehouseId(Long warehouseId);
    List<WarehouseAssignment> findByUserIdAndActiveTrue(Long userId);
    Optional<WarehouseAssignment> findByUserIdAndWarehouseId(Long userId, Long warehouseId);
    Optional<WarehouseAssignment> findByUserIdAndIsPrimaryTrue(Long userId);
}
