package com.azulejosromu.orders_service.controller;

import com.azulejosromu.orders_service.model.Order;
import com.azulejosromu.orders_service.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/orders")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @GetMapping
    public ResponseEntity<List<Order>> getAll() {
        return ResponseEntity.ok(orderService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Order> getById(@PathVariable Long id) {
        return orderService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/number/{orderNumber}")
    public ResponseEntity<Order> getByOrderNumber(@PathVariable String orderNumber) {
        return orderService.findByOrderNumber(orderNumber)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/type/{orderType}")
    public ResponseEntity<List<Order>> getByType(@PathVariable Order.OrderType orderType) {
        return ResponseEntity.ok(orderService.findByOrderType(orderType));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<Order>> getByStatus(@PathVariable Order.OrderStatus status) {
        return ResponseEntity.ok(orderService.findByStatus(status));
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<List<Order>> getByCustomer(@PathVariable Long customerId) {
        return ResponseEntity.ok(orderService.findByCustomerId(customerId));
    }

    @GetMapping("/supplier/{supplierId}")
    public ResponseEntity<List<Order>> getBySupplier(@PathVariable Long supplierId) {
        return ResponseEntity.ok(orderService.findBySupplierId(supplierId));
    }

    @GetMapping("/warehouse/{warehouseId}")
    public ResponseEntity<List<Order>> getByWarehouse(@PathVariable Long warehouseId) {
        return ResponseEntity.ok(orderService.findByWarehouseId(warehouseId));
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<Order>> getByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        return ResponseEntity.ok(orderService.findByDateRange(start, end));
    }

    @PostMapping
    public ResponseEntity<Order> create(@RequestBody Order order) {
        Order saved = orderService.save(order);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Order> update(@PathVariable Long id, @RequestBody Order order) {
        if (!orderService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        order.setId(id);
        Order updated = orderService.save(order);
        return ResponseEntity.ok(updated);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<Order> updateStatus(@PathVariable Long id, @RequestBody Map<String, Object> request) {
        Order.OrderStatus newStatus = Order.OrderStatus.valueOf(request.get("status").toString());
        Long userId = request.get("userId") != null ? Long.valueOf(request.get("userId").toString()) : 1L;
        String notes = request.get("notes") != null ? request.get("notes").toString() : "";

        Order updated = orderService.updateStatus(id, newStatus, userId, notes);
        return ResponseEntity.ok(updated);
    }

    @GetMapping("/verify-stock/{productId}/{warehouseId}/{quantity}")
    public ResponseEntity<Boolean> verifyStock(
            @PathVariable Long productId,
            @PathVariable Long warehouseId,
            @PathVariable Integer quantity) {
        boolean available = orderService.verifyStock(productId, warehouseId, quantity);
        return ResponseEntity.ok(available);
    }
}
