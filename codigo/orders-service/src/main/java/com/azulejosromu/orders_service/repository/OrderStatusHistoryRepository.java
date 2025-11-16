package com.azulejosromu.orders_service.repository;

import com.azulejosromu.orders_service.model.OrderStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderStatusHistoryRepository extends JpaRepository<OrderStatusHistory, Long> {
    List<OrderStatusHistory> findByOrderId(Long orderId);
    List<OrderStatusHistory> findByOrderIdOrderByChangedAtDesc(Long orderId);
}
