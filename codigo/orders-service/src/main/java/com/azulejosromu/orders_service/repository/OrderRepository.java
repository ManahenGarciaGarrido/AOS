package com.azulejosromu.orders_service.repository;

import com.azulejosromu.orders_service.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    Optional<Order> findByOrderNumber(String orderNumber);
    List<Order> findByOrderType(Order.OrderType orderType);
    List<Order> findByStatus(Order.OrderStatus status);
    List<Order> findByCustomerId(Long customerId);
    List<Order> findBySupplierId(Long supplierId);
    List<Order> findByWarehouseId(Long warehouseId);
    List<Order> findByCreatedAtBetween(LocalDateTime start, LocalDateTime end);
}
