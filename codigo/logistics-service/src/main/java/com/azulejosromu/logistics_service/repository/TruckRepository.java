package com.azulejosromu.logistics_service.repository;

import com.azulejosromu.logistics_service.model.Truck;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TruckRepository extends JpaRepository<Truck, Long> {
    Optional<Truck> findByLicensePlate(String licensePlate);
    List<Truck> findByStatus(Truck.TruckStatus status);
    List<Truck> findByActiveTrue();
}
