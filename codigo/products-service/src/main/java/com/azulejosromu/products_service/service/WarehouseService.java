package com.azulejosromu.products_service.service;

import com.azulejosromu.products_service.model.Warehouse;
import com.azulejosromu.products_service.repository.WarehouseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class WarehouseService {

    @Autowired
    private WarehouseRepository warehouseRepository;

    public List<Warehouse> findAll() {
        return warehouseRepository.findAll();
    }

    public Optional<Warehouse> findById(Long id) {
        return warehouseRepository.findById(id);
    }

    public Optional<Warehouse> findByCode(String code) {
        return warehouseRepository.findByCode(code);
    }

    public List<Warehouse> findActiveWarehouses() {
        return warehouseRepository.findByActiveTrue();
    }

    public List<Warehouse> findByCity(String city) {
        return warehouseRepository.findByCity(city);
    }

    @Transactional
    public Warehouse save(Warehouse warehouse) {
        warehouse.setUpdatedAt(LocalDateTime.now());
        if (warehouse.getId() == null) {
            warehouse.setCreatedAt(LocalDateTime.now());
        }
        return warehouseRepository.save(warehouse);
    }

    @Transactional
    public void deleteById(Long id) {
        Warehouse warehouse = findById(id)
                .orElseThrow(() -> new RuntimeException("Warehouse not found with id: " + id));
        warehouse.setActive(false);
        warehouse.setUpdatedAt(LocalDateTime.now());
        save(warehouse);
    }
}
