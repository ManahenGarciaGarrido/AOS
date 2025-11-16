package com.azulejosromu.users_service.controller;

import com.azulejosromu.users_service.model.WarehouseAssignment;
import com.azulejosromu.users_service.repository.WarehouseAssignmentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/warehouse-assignments")
public class WarehouseAssignmentController {

    @Autowired
    private WarehouseAssignmentRepository warehouseAssignmentRepository;

    @GetMapping
    public ResponseEntity<List<WarehouseAssignment>> getAll() {
        return ResponseEntity.ok(warehouseAssignmentRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<WarehouseAssignment> getById(@PathVariable Long id) {
        return warehouseAssignmentRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<WarehouseAssignment>> getByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(warehouseAssignmentRepository.findByUserId(userId));
    }

    @GetMapping("/user/{userId}/current")
    public ResponseEntity<List<WarehouseAssignment>> getCurrentByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(warehouseAssignmentRepository.findByUserIdAndIsCurrentTrue(userId));
    }

    @GetMapping("/warehouse/{warehouseId}")
    public ResponseEntity<List<WarehouseAssignment>> getByWarehouse(@PathVariable Long warehouseId) {
        return ResponseEntity.ok(warehouseAssignmentRepository.findByWarehouseId(warehouseId));
    }

    @GetMapping("/warehouse/{warehouseId}/current")
    public ResponseEntity<List<WarehouseAssignment>> getCurrentByWarehouse(@PathVariable Long warehouseId) {
        return ResponseEntity.ok(warehouseAssignmentRepository.findByWarehouseIdAndIsCurrentTrue(warehouseId));
    }

    @GetMapping("/date/{date}")
    public ResponseEntity<List<WarehouseAssignment>> getByDate(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(warehouseAssignmentRepository.findByAssignmentDate(date));
    }

    @PostMapping
    public ResponseEntity<WarehouseAssignment> create(@RequestBody WarehouseAssignment assignment) {
        if (assignment.getAssignmentDate() == null) {
            assignment.setAssignmentDate(LocalDate.now());
        }
        if (assignment.getIsCurrent() == null) {
            assignment.setIsCurrent(true);
        }
        WarehouseAssignment saved = warehouseAssignmentRepository.save(assignment);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<WarehouseAssignment> update(@PathVariable Long id, @RequestBody WarehouseAssignment assignment) {
        if (!warehouseAssignmentRepository.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        assignment.setId(id);
        WarehouseAssignment updated = warehouseAssignmentRepository.save(assignment);
        return ResponseEntity.ok(updated);
    }

    @PutMapping("/{id}/deactivate")
    public ResponseEntity<WarehouseAssignment> deactivate(@PathVariable Long id) {
        return warehouseAssignmentRepository.findById(id)
                .map(assignment -> {
                    assignment.setIsCurrent(false);
                    WarehouseAssignment updated = warehouseAssignmentRepository.save(assignment);
                    return ResponseEntity.ok(updated);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        warehouseAssignmentRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
