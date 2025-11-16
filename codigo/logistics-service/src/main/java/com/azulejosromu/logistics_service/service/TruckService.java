package com.azulejosromu.logistics_service.service;

import com.azulejosromu.logistics_service.model.Truck;
import com.azulejosromu.logistics_service.repository.TruckRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class TruckService {

    @Autowired
    private TruckRepository truckRepository;

    public List<Truck> findAll() {
        return truckRepository.findAll();
    }

    public Optional<Truck> findById(Long id) {
        return truckRepository.findById(id);
    }

    public Optional<Truck> findByLicensePlate(String licensePlate) {
        return truckRepository.findByLicensePlate(licensePlate);
    }

    public List<Truck> findByStatus(Truck.TruckStatus status) {
        return truckRepository.findByStatus(status);
    }

    public List<Truck> findActiveTrucks() {
        return truckRepository.findByActiveTrue();
    }

    @Transactional
    public Truck save(Truck truck) {
        truck.setUpdatedAt(LocalDateTime.now());
        if (truck.getId() == null) {
            truck.setCreatedAt(LocalDateTime.now());
        }
        return truckRepository.save(truck);
    }

    @Transactional
    public void deleteById(Long id) {
        Truck truck = findById(id)
                .orElseThrow(() -> new RuntimeException("Truck not found with id: " + id));
        truck.setActive(false);
        truck.setUpdatedAt(LocalDateTime.now());
        save(truck);
    }
}
