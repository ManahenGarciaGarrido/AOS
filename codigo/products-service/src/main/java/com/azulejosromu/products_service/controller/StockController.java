package com.azulejosromu.products_service.controller;

import com.azulejosromu.products_service.model.Stock;
import com.azulejosromu.products_service.model.StockMovement;
import com.azulejosromu.products_service.service.StockService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/stock")
public class StockController {

    @Autowired
    private StockService stockService;

    @GetMapping
    public ResponseEntity<List<Stock>> getAll() {
        return ResponseEntity.ok(stockService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Stock> getById(@PathVariable Long id) {
        return stockService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/product/{productId}")
    public ResponseEntity<List<Stock>> getByProduct(@PathVariable Long productId) {
        return ResponseEntity.ok(stockService.findByProductId(productId));
    }

    @GetMapping("/warehouse/{warehouseId}")
    public ResponseEntity<List<Stock>> getByWarehouse(@PathVariable Long warehouseId) {
        return ResponseEntity.ok(stockService.findByWarehouseId(warehouseId));
    }

    @GetMapping("/product/{productId}/warehouse/{warehouseId}")
    public ResponseEntity<Stock> getByProductAndWarehouse(
            @PathVariable Long productId,
            @PathVariable Long warehouseId) {
        return stockService.findByProductAndWarehouse(productId, warehouseId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/low-stock")
    public ResponseEntity<List<Stock>> getLowStock() {
        return ResponseEntity.ok(stockService.findLowStockItems());
    }

    @GetMapping("/reorder")
    public ResponseEntity<List<Stock>> getItemsToReorder() {
        return ResponseEntity.ok(stockService.findItemsToReorder());
    }

    @GetMapping("/verify/{productId}/{warehouseId}/{quantity}")
    public ResponseEntity<Boolean> verifyStock(
            @PathVariable Long productId,
            @PathVariable Long warehouseId,
            @PathVariable Integer quantity) {
        boolean available = stockService.verifyStock(productId, warehouseId, quantity);
        return ResponseEntity.ok(available);
    }

    @PostMapping
    public ResponseEntity<Stock> create(@RequestBody Stock stock) {
        Stock saved = stockService.save(stock);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Stock> update(@PathVariable Long id, @RequestBody Stock stock) {
        if (!stockService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        stock.setId(id);
        Stock updated = stockService.save(stock);
        return ResponseEntity.ok(updated);
    }

    @PostMapping("/adjust")
    public ResponseEntity<Void> adjustStock(@RequestBody Map<String, Object> request) {
        Long productId = Long.valueOf(request.get("productId").toString());
        Long warehouseId = Long.valueOf(request.get("warehouseId").toString());
        Integer quantity = Integer.valueOf(request.get("quantity").toString());
        StockMovement.MovementType movementType = StockMovement.MovementType.valueOf(request.get("movementType").toString());
        String notes = request.get("notes") != null ? request.get("notes").toString() : "";
        Long userId = request.get("userId") != null ? Long.valueOf(request.get("userId").toString()) : 1L;

        stockService.adjustStock(productId, warehouseId, quantity, movementType, notes, userId);
        return ResponseEntity.ok().build();
    }
}
