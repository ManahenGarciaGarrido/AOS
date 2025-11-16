package com.azulejosromu.products_service.controller;

import com.azulejosromu.products_service.model.Warehouse;
import com.azulejosromu.products_service.service.WarehouseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/warehouses")
public class WarehouseController {

    @Autowired
    private WarehouseService warehouseService;

    @GetMapping
    public ResponseEntity<List<Warehouse>> getAll() {
        return ResponseEntity.ok(warehouseService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Warehouse> getById(@PathVariable Long id) {
        return warehouseService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/code/{code}")
    public ResponseEntity<Warehouse> getByCode(@PathVariable String code) {
        return warehouseService.findByCode(code)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/active")
    public ResponseEntity<List<Warehouse>> getActive() {
        return ResponseEntity.ok(warehouseService.findActiveWarehouses());
    }

    @GetMapping("/city/{city}")
    public ResponseEntity<List<Warehouse>> getByCity(@PathVariable String city) {
        return ResponseEntity.ok(warehouseService.findByCity(city));
    }

    @PostMapping
    public ResponseEntity<Warehouse> create(@RequestBody Warehouse warehouse) {
        Warehouse saved = warehouseService.save(warehouse);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Warehouse> update(@PathVariable Long id, @RequestBody Warehouse warehouse) {
        if (!warehouseService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        warehouse.setId(id);
        Warehouse updated = warehouseService.save(warehouse);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        warehouseService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
