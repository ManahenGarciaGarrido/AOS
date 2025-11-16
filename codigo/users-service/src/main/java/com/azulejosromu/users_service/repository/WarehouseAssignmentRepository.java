package com.azulejosromu.users_service.repository;

import com.azulejosromu.users_service.model.WarehouseAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface WarehouseAssignmentRepository extends JpaRepository<WarehouseAssignment, Long> {
    List<WarehouseAssignment> findByUserId(Long userId);
    List<WarehouseAssignment> findByWarehouseId(Long warehouseId);
    List<WarehouseAssignment> findByUserIdAndIsCurrentTrue(Long userId);
    List<WarehouseAssignment> findByWarehouseIdAndIsCurrentTrue(Long warehouseId);
    List<WarehouseAssignment> findByAssignmentDate(LocalDate assignmentDate);
    Optional<WarehouseAssignment> findByUserIdAndWarehouseId(Long userId, Long warehouseId);
}
