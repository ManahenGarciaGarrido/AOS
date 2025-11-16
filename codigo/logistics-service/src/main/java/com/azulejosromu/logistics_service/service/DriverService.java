package com.azulejosromu.logistics_service.service;

import com.azulejosromu.logistics_service.model.Driver;
import com.azulejosromu.logistics_service.repository.DriverRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class DriverService {

    @Autowired
    private DriverRepository driverRepository;

    public List<Driver> findAll() {
        return driverRepository.findAll();
    }

    public Optional<Driver> findById(Long id) {
        return driverRepository.findById(id);
    }

    public Optional<Driver> findByNif(String nif) {
        return driverRepository.findByNif(nif);
    }

    public Optional<Driver> findByLicenseNumber(String licenseNumber) {
        return driverRepository.findByLicenseNumber(licenseNumber);
    }

    public List<Driver> findByStatus(Driver.DriverStatus status) {
        return driverRepository.findByStatus(status);
    }

    public List<Driver> findActiveDrivers() {
        return driverRepository.findByActiveTrue();
    }

    @Transactional
    public Driver save(Driver driver) {
        driver.setUpdatedAt(LocalDateTime.now());
        if (driver.getId() == null) {
            driver.setCreatedAt(LocalDateTime.now());
        }
        return driverRepository.save(driver);
    }

    @Transactional
    public void deleteById(Long id) {
        Driver driver = findById(id)
                .orElseThrow(() -> new RuntimeException("Driver not found with id: " + id));
        driver.setActive(false);
        driver.setUpdatedAt(LocalDateTime.now());
        save(driver);
    }
}
