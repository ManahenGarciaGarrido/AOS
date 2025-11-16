package com.azulejosromu.products_service.repository;

import com.azulejosromu.products_service.model.Supplier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SupplierRepository extends JpaRepository<Supplier, Long> {
    Optional<Supplier> findByNif(String nif);
    List<Supplier> findByActiveTrue();
    List<Supplier> findByCountry(String country);
}
