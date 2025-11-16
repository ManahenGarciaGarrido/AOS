package com.azulejosromu.logistics_service.repository;

import com.azulejosromu.logistics_service.model.GpsTracking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface GpsTrackingRepository extends JpaRepository<GpsTracking, Long> {
    List<GpsTracking> findByRouteId(Long routeId);
    List<GpsTracking> findByTruckId(Long truckId);
    List<GpsTracking> findByTruckIdOrderByRecordedAtDesc(Long truckId);
    List<GpsTracking> findByRouteIdOrderByRecordedAtDesc(Long routeId);
    List<GpsTracking> findByRecordedAtBetween(LocalDateTime start, LocalDateTime end);
}
