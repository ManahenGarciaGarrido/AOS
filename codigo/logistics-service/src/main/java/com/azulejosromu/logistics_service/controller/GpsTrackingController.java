package com.azulejosromu.logistics_service.controller;

import com.azulejosromu.logistics_service.model.GpsTracking;
import com.azulejosromu.logistics_service.repository.GpsTrackingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/tracking")
public class GpsTrackingController {

    @Autowired
    private GpsTrackingRepository gpsTrackingRepository;

    @GetMapping
    public ResponseEntity<List<GpsTracking>> getAll() {
        return ResponseEntity.ok(gpsTrackingRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<GpsTracking> getById(@PathVariable Long id) {
        return gpsTrackingRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/truck/{truckId}")
    public ResponseEntity<List<GpsTracking>> getByTruck(@PathVariable Long truckId) {
        return ResponseEntity.ok(gpsTrackingRepository.findByTruckId(truckId));
    }

    @GetMapping("/truck/{truckId}/latest")
    public ResponseEntity<GpsTracking> getLatestByTruck(@PathVariable Long truckId) {
        List<GpsTracking> tracking = gpsTrackingRepository.findByTruckIdOrderByRecordedAtDesc(truckId);
        if (tracking.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(tracking.get(0));
    }

    @GetMapping("/route/{routeId}")
    public ResponseEntity<List<GpsTracking>> getByRoute(@PathVariable Long routeId) {
        return ResponseEntity.ok(gpsTrackingRepository.findByRouteId(routeId));
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<GpsTracking>> getByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        return ResponseEntity.ok(gpsTrackingRepository.findByRecordedAtBetween(start, end));
    }

    @PostMapping
    public ResponseEntity<GpsTracking> create(@RequestBody GpsTracking gpsTracking) {
        if (gpsTracking.getRecordedAt() == null) {
            gpsTracking.setRecordedAt(LocalDateTime.now());
        }
        GpsTracking saved = gpsTrackingRepository.save(gpsTracking);
        return ResponseEntity.status(201).body(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        gpsTrackingRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
