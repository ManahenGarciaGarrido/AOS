package com.azulejosromu.logistics_service.controller;

import com.azulejosromu.logistics_service.model.Truck;
import com.azulejosromu.logistics_service.service.TruckService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/trucks")
public class TruckController {

    @Autowired
    private TruckService truckService;

    @GetMapping
    public ResponseEntity<List<Truck>> getAll() {
        return ResponseEntity.ok(truckService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Truck> getById(@PathVariable Long id) {
        return truckService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/license/{licensePlate}")
    public ResponseEntity<Truck> getByLicensePlate(@PathVariable String licensePlate) {
        return truckService.findByLicensePlate(licensePlate)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<Truck>> getByStatus(@PathVariable Truck.TruckStatus status) {
        return ResponseEntity.ok(truckService.findByStatus(status));
    }

    @GetMapping("/active")
    public ResponseEntity<List<Truck>> getActive() {
        return ResponseEntity.ok(truckService.findActiveTrucks());
    }

    @PostMapping
    public ResponseEntity<Truck> create(@RequestBody Truck truck) {
        Truck saved = truckService.save(truck);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Truck> update(@PathVariable Long id, @RequestBody Truck truck) {
        if (!truckService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        truck.setId(id);
        Truck updated = truckService.save(truck);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        truckService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
