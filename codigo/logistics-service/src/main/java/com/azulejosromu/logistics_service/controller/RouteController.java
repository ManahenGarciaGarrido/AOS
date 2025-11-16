package com.azulejosromu.logistics_service.controller;

import com.azulejosromu.logistics_service.model.Route;
import com.azulejosromu.logistics_service.service.RouteOptimizationService;
import com.azulejosromu.logistics_service.service.RouteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/routes")
public class RouteController {

    @Autowired
    private RouteService routeService;

    @Autowired
    private RouteOptimizationService optimizationService;

    @GetMapping
    public ResponseEntity<List<Route>> getAll() {
        return ResponseEntity.ok(routeService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Route> getById(@PathVariable Long id) {
        return routeService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/code/{routeCode}")
    public ResponseEntity<Route> getByRouteCode(@PathVariable String routeCode) {
        return routeService.findByRouteCode(routeCode)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/truck/{truckId}")
    public ResponseEntity<List<Route>> getByTruck(@PathVariable Long truckId) {
        return ResponseEntity.ok(routeService.findByTruckId(truckId));
    }

    @GetMapping("/driver/{driverId}")
    public ResponseEntity<List<Route>> getByDriver(@PathVariable Long driverId) {
        return ResponseEntity.ok(routeService.findByDriverId(driverId));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<Route>> getByStatus(@PathVariable Route.RouteStatus status) {
        return ResponseEntity.ok(routeService.findByStatus(status));
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<Route>> getByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        return ResponseEntity.ok(routeService.findByDateRange(start, end));
    }

    @PostMapping
    public ResponseEntity<Route> create(@RequestBody Route route) {
        Route saved = routeService.save(route);
        return ResponseEntity.status(201).body(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Route> update(@PathVariable Long id, @RequestBody Route route) {
        if (!routeService.findById(id).isPresent()) {
            return ResponseEntity.notFound().build();
        }
        route.setId(id);
        Route updated = routeService.save(route);
        return ResponseEntity.ok(updated);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<Route> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> request) {
        Route.RouteStatus newStatus = Route.RouteStatus.valueOf(request.get("status"));
        Route updated = routeService.updateStatus(id, newStatus);
        return ResponseEntity.ok(updated);
    }

    @PostMapping("/optimize")
    public ResponseEntity<Route> optimizeRoute(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Long> orderIds = (List<Long>) request.get("orderIds");
        Long truckId = Long.valueOf(request.get("truckId").toString());
        Long driverId = Long.valueOf(request.get("driverId").toString());

        Route optimizedRoute = optimizationService.optimizeRoute(orderIds, truckId, driverId);
        return ResponseEntity.status(201).body(optimizedRoute);
    }
}
