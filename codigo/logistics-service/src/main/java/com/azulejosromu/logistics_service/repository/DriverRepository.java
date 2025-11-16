package com.azulejosromu.logistics_service.repository;

import com.azulejosromu.logistics_service.model.Driver;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DriverRepository extends JpaRepository<Driver, Long> {
    Optional<Driver> findByNif(String nif);
    Optional<Driver> findByLicenseNumber(String licenseNumber);
    List<Driver> findByStatus(Driver.DriverStatus status);
    List<Driver> findByActiveTrue();
}
