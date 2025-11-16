package com.azulejosromu.logistics_service.controller;

import com.azulejosromu.logistics_service.model.Driver;
import com.azulejosromu.logistics_service.service.DriverService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/drivers")
public class DriverController {

    @Autowired
    private DriverService driverService;

    @GetMapping
    public ResponseEntity<List<Driver>> getAll() {
        return ResponseEntity.ok(driverService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Driver> getById(@PathVariable Long id) {
        return driverService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/nif/{nif}")
    public ResponseEntity<Driver> getByNif(@PathVariable String nif) {
        return driverService.findByNif(nif)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/license/{licenseNumber}")
    public ResponseEntity<Driver> getByLicenseNumber(@PathVariable String licenseNumber) {
        return driverService.findByLicenseNumber(licenseNumber)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<Driver>> getByStatus(@PathVariable Driver.DriverStatus status) {
        return ResponseEntity.ok(driverService.findByStatus(status));
    }

    @GetMapping("/active")
    public ResponseEntity<List<Driver>> getActive() {
        return ResponseEntity.ok(driverService.findActiveDrivers());
    }

    @PostMapping
    public ResponseEntity<Driver> create(@RequestBody Driver driver) {
        Driver saved = driverService.save(driver);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Driver> update(@PathVariable Long id, @RequestBody Driver driver) {
        if (!driverService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        driver.setId(id);
        Driver updated = driverService.save(driver);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        driverService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
