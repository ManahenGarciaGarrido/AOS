package com.azulejosromu.products_service.service;

import com.azulejosromu.products_service.model.StockMovement;
import com.azulejosromu.products_service.repository.StockMovementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class StockMovementService {

    @Autowired
    private StockMovementRepository stockMovementRepository;

    public List<StockMovement> findAll() {
        return stockMovementRepository.findAll();
    }

    public Optional<StockMovement> findById(Long id) {
        return stockMovementRepository.findById(id);
    }

    public List<StockMovement> findByProductId(Long productId) {
        return stockMovementRepository.findByProductId(productId);
    }

    public List<StockMovement> findByWarehouseId(Long warehouseId) {
        return stockMovementRepository.findByWarehouseId(warehouseId);
    }

    public List<StockMovement> findByMovementType(StockMovement.MovementType movementType) {
        return stockMovementRepository.findByMovementType(movementType);
    }

    public List<StockMovement> findByDateRange(LocalDateTime start, LocalDateTime end) {
        return stockMovementRepository.findByCreatedAtBetween(start, end);
    }

    public List<StockMovement> findByProductAndWarehouse(Long productId, Long warehouseId) {
        return stockMovementRepository.findByProductIdAndWarehouseId(productId, warehouseId);
    }

    @Transactional
    public StockMovement save(StockMovement stockMovement) {
        if (stockMovement.getId() == null) {
            stockMovement.setCreatedAt(LocalDateTime.now());
        }
        return stockMovementRepository.save(stockMovement);
    }
}
