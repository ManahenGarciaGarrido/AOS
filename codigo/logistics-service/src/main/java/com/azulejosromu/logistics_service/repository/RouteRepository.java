package com.azulejosromu.logistics_service.repository;

import com.azulejosromu.logistics_service.model.Route;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RouteRepository extends JpaRepository<Route, Long> {
    Optional<Route> findByRouteCode(String routeCode);
    List<Route> findByTruckId(Long truckId);
    List<Route> findByDriverId(Long driverId);
    List<Route> findByStatus(Route.RouteStatus status);
    List<Route> findByScheduledStartBetween(LocalDateTime start, LocalDateTime end);
}
