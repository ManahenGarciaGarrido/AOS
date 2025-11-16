package com.azulejosromu.products_service.controller;

import com.azulejosromu.products_service.model.Supplier;
import com.azulejosromu.products_service.service.SupplierService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/suppliers")
public class SupplierController {

    @Autowired
    private SupplierService supplierService;

    @GetMapping
    public ResponseEntity<List<Supplier>> getAll() {
        return ResponseEntity.ok(supplierService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Supplier> getById(@PathVariable Long id) {
        return supplierService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/nif/{nif}")
    public ResponseEntity<Supplier> getByNif(@PathVariable String nif) {
        return supplierService.findByNif(nif)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/active")
    public ResponseEntity<List<Supplier>> getActive() {
        return ResponseEntity.ok(supplierService.findActiveSuppliers());
    }

    @GetMapping("/country/{country}")
    public ResponseEntity<List<Supplier>> getByCountry(@PathVariable String country) {
        return ResponseEntity.ok(supplierService.findByCountry(country));
    }

    @PostMapping
    public ResponseEntity<Supplier> create(@RequestBody Supplier supplier) {
        Supplier saved = supplierService.save(supplier);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Supplier> update(@PathVariable Long id, @RequestBody Supplier supplier) {
        if (!supplierService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        supplier.setId(id);
        Supplier updated = supplierService.save(supplier);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        supplierService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
