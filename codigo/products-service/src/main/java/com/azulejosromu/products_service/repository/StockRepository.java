package com.azulejosromu.products_service.repository;

import com.azulejosromu.products_service.model.Stock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StockRepository extends JpaRepository<Stock, Long> {
    Optional<Stock> findByProductIdAndWarehouseId(Long productId, Long warehouseId);
    List<Stock> findByProductId(Long productId);
    List<Stock> findByWarehouseId(Long warehouseId);

    @Query("SELECT s FROM Stock s WHERE s.quantity <= s.minStock")
    List<Stock> findLowStockItems();

    @Query("SELECT s FROM Stock s WHERE s.quantity <= s.reorderPoint")
    List<Stock> findItemsToReorder();
}
