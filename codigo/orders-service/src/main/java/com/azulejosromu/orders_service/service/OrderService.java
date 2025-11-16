package com.azulejosromu.orders_service.service;

import com.azulejosromu.orders_service.model.Order;
import com.azulejosromu.orders_service.model.OrderItem;
import com.azulejosromu.orders_service.model.OrderStatusHistory;
import com.azulejosromu.orders_service.repository.OrderRepository;
import com.azulejosromu.orders_service.repository.OrderStatusHistoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.net.URI;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderStatusHistoryRepository statusHistoryRepository;

    @Autowired
    private DiscoveryClient discoveryClient;

    public List<Order> findAll() {
        return orderRepository.findAll();
    }

    public Optional<Order> findById(Long id) {
        return orderRepository.findById(id);
    }

    public Optional<Order> findByOrderNumber(String orderNumber) {
        return orderRepository.findByOrderNumber(orderNumber);
    }

    public List<Order> findByOrderType(Order.OrderType orderType) {
        return orderRepository.findByOrderType(orderType);
    }

    public List<Order> findByStatus(Order.OrderStatus status) {
        return orderRepository.findByStatus(status);
    }

    public List<Order> findByCustomerId(Long customerId) {
        return orderRepository.findByCustomerId(customerId);
    }

    public List<Order> findBySupplierId(Long supplierId) {
        return orderRepository.findBySupplierId(supplierId);
    }

    public List<Order> findByWarehouseId(Long warehouseId) {
        return orderRepository.findByWarehouseId(warehouseId);
    }

    public List<Order> findByDateRange(LocalDateTime start, LocalDateTime end) {
        return orderRepository.findByCreatedAtBetween(start, end);
    }

    @Transactional
    public Order save(Order order) {
        order.setUpdatedAt(LocalDateTime.now());
        if (order.getId() == null) {
            order.setCreatedAt(LocalDateTime.now());
            // Generar número de pedido
            if (order.getOrderNumber() == null || order.getOrderNumber().isEmpty()) {
                order.setOrderNumber(generateOrderNumber(order.getOrderType()));
            }
        }

        // Calcular totales
        if (order.getItems() != null && !order.getItems().isEmpty()) {
            BigDecimal total = BigDecimal.ZERO;
            for (OrderItem item : order.getItems()) {
                item.setOrder(order);
                total = total.add(item.getSubtotal());
            }
            order.setTotalAmount(total.add(order.getTax()).add(order.getShipping()));
        }

        return orderRepository.save(order);
    }

    @Transactional
    public Order updateStatus(Long orderId, Order.OrderStatus newStatus, Long userId, String notes) {
        Order order = findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + orderId));

        Order.OrderStatus previousStatus = order.getStatus();
        order.setStatus(newStatus);
        order.setUpdatedAt(LocalDateTime.now());

        // Registrar cambio de estado
        OrderStatusHistory history = new OrderStatusHistory();
        history.setOrderId(orderId);
        history.setPreviousStatus(previousStatus);
        history.setNewStatus(newStatus);
        history.setChangedBy(userId);
        history.setNotes(notes);
        history.setChangedAt(LocalDateTime.now());
        statusHistoryRepository.save(history);

        return orderRepository.save(order);
    }

    public boolean verifyStock(Long productId, Long warehouseId, Integer quantity) {
        try {
            List<ServiceInstance> instances = discoveryClient.getInstances("products-service");

            if (instances != null && !instances.isEmpty()) {
                ServiceInstance instance = instances.get(0);
                URI uri = instance.getUri();

                String url = uri + "/stock/verify/" + productId + "/" + warehouseId + "/" + quantity;
                RestTemplate restTemplate = new RestTemplate();

                Boolean result = restTemplate.getForObject(url, Boolean.class);
                return result != null && result;
            }
        } catch (Exception e) {
            System.err.println("Error verifying stock: " + e.getMessage());
        }
        return false;
    }

    private String generateOrderNumber(Order.OrderType orderType) {
        String prefix = switch (orderType) {
            case CLIENTE -> "CLI";
            case REPOSICION -> "REP";
            case PROVEEDOR -> "PRO";
        };

        String timestamp = String.valueOf(System.currentTimeMillis());
        return prefix + "-" + timestamp;
    }
}
