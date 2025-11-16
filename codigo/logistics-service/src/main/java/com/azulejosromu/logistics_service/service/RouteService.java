package com.azulejosromu.logistics_service.service;

import com.azulejosromu.logistics_service.model.Route;
import com.azulejosromu.logistics_service.repository.RouteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class RouteService {

    @Autowired
    private RouteRepository routeRepository;

    public List<Route> findAll() {
        return routeRepository.findAll();
    }

    public Optional<Route> findById(Long id) {
        return routeRepository.findById(id);
    }

    public Optional<Route> findByRouteCode(String routeCode) {
        return routeRepository.findByRouteCode(routeCode);
    }

    public List<Route> findByTruckId(Long truckId) {
        return routeRepository.findByTruckId(truckId);
    }

    public List<Route> findByDriverId(Long driverId) {
        return routeRepository.findByDriverId(driverId);
    }

    public List<Route> findByStatus(Route.RouteStatus status) {
        return routeRepository.findByStatus(status);
    }

    public List<Route> findByDateRange(LocalDateTime start, LocalDateTime end) {
        return routeRepository.findByScheduledStartBetween(start, end);
    }

    @Transactional
    public Route save(Route route) {
        route.setUpdatedAt(LocalDateTime.now());
        if (route.getId() == null) {
            route.setCreatedAt(LocalDateTime.now());
        }
        return routeRepository.save(route);
    }

    @Transactional
    public Route updateStatus(Long routeId, Route.RouteStatus newStatus) {
        Route route = findById(routeId)
                .orElseThrow(() -> new RuntimeException("Route not found with id: " + routeId));

        route.setStatus(newStatus);
        route.setUpdatedAt(LocalDateTime.now());

        if (newStatus == Route.RouteStatus.EN_CURSO && route.getActualStart() == null) {
            route.setActualStart(LocalDateTime.now());
        } else if (newStatus == Route.RouteStatus.COMPLETADA && route.getActualEnd() == null) {
            route.setActualEnd(LocalDateTime.now());
        }

        return routeRepository.save(route);
    }
}
