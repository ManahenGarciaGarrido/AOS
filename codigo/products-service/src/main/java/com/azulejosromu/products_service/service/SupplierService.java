package com.azulejosromu.products_service.service;

import com.azulejosromu.products_service.model.Supplier;
import com.azulejosromu.products_service.repository.SupplierRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class SupplierService {

    @Autowired
    private SupplierRepository supplierRepository;

    public List<Supplier> findAll() {
        return supplierRepository.findAll();
    }

    public Optional<Supplier> findById(Long id) {
        return supplierRepository.findById(id);
    }

    public Optional<Supplier> findByNif(String nif) {
        return supplierRepository.findByNif(nif);
    }

    public List<Supplier> findActiveSuppliers() {
        return supplierRepository.findByActiveTrue();
    }

    public List<Supplier> findByCountry(String country) {
        return supplierRepository.findByCountry(country);
    }

    @Transactional
    public Supplier save(Supplier supplier) {
        supplier.setUpdatedAt(LocalDateTime.now());
        if (supplier.getId() == null) {
            supplier.setCreatedAt(LocalDateTime.now());
        }
        return supplierRepository.save(supplier);
    }

    @Transactional
    public void deleteById(Long id) {
        Supplier supplier = findById(id)
                .orElseThrow(() -> new RuntimeException("Supplier not found with id: " + id));
        supplier.setActive(false);
        supplier.setUpdatedAt(LocalDateTime.now());
        save(supplier);
    }
}
