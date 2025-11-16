package com.azulejosromu.products_service.service;

import com.azulejosromu.products_service.model.Stock;
import com.azulejosromu.products_service.model.StockMovement;
import com.azulejosromu.products_service.repository.StockRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class StockService {

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockMovementService stockMovementService;

    public List<Stock> findAll() {
        return stockRepository.findAll();
    }

    public Optional<Stock> findById(Long id) {
        return stockRepository.findById(id);
    }

    public Optional<Stock> findByProductAndWarehouse(Long productId, Long warehouseId) {
        return stockRepository.findByProductIdAndWarehouseId(productId, warehouseId);
    }

    public List<Stock> findByProductId(Long productId) {
        return stockRepository.findByProductId(productId);
    }

    public List<Stock> findByWarehouseId(Long warehouseId) {
        return stockRepository.findByWarehouseId(warehouseId);
    }

    public List<Stock> findLowStockItems() {
        return stockRepository.findLowStockItems();
    }

    public List<Stock> findItemsToReorder() {
        return stockRepository.findItemsToReorder();
    }

    @Transactional
    public Stock save(Stock stock) {
        stock.setUpdatedAt(LocalDateTime.now());
        if (stock.getId() == null) {
            stock.setCreatedAt(LocalDateTime.now());
        }
        return stockRepository.save(stock);
    }

    @Transactional
    public boolean verifyStock(Long productId, Long warehouseId, Integer quantity) {
        Optional<Stock> stockOpt = findByProductAndWarehouse(productId, warehouseId);
        if (stockOpt.isPresent()) {
            Stock stock = stockOpt.get();
            return stock.getQuantity() >= quantity;
        }
        return false;
    }

    @Transactional
    public void adjustStock(Long productId, Long warehouseId, Integer quantity,
                           StockMovement.MovementType movementType, String notes, Long userId) {
        Optional<Stock> stockOpt = findByProductAndWarehouse(productId, warehouseId);
        Stock stock;

        if (stockOpt.isPresent()) {
            stock = stockOpt.get();
        } else {
            stock = new Stock();
            stock.setProductId(productId);
            stock.setWarehouseId(warehouseId);
            stock.setQuantity(0);
        }

        // Ajustar cantidad según tipo de movimiento
        if (movementType == StockMovement.MovementType.ENTRADA ||
            movementType == StockMovement.MovementType.DEVOLUCION) {
            stock.setQuantity(stock.getQuantity() + quantity);
        } else if (movementType == StockMovement.MovementType.SALIDA) {
            stock.setQuantity(stock.getQuantity() - quantity);
        } else if (movementType == StockMovement.MovementType.AJUSTE) {
            stock.setQuantity(quantity);
        }

        stock.setLastStockCheck(LocalDateTime.now());
        save(stock);

        // Registrar movimiento
        StockMovement movement = new StockMovement();
        movement.setProductId(productId);
        movement.setWarehouseId(warehouseId);
        movement.setMovementType(movementType);
        movement.setQuantity(quantity);
        movement.setNotes(notes);
        movement.setCreatedBy(userId);
        stockMovementService.save(movement);
    }
}
