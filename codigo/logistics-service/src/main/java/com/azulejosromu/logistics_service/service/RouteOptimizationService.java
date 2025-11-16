package com.azulejosromu.logistics_service.service;

import com.azulejosromu.logistics_service.model.Route;
import com.azulejosromu.logistics_service.model.RouteStop;
import com.azulejosromu.logistics_service.repository.RouteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.net.URI;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class RouteOptimizationService {

    @Autowired
    private RouteRepository routeRepository;

    @Autowired
    private DiscoveryClient discoveryClient;

    // Coordenadas del almacén por defecto (Ejemplo: Madrid)
    private static final BigDecimal WAREHOUSE_LAT = new BigDecimal("40.4168");
    private static final BigDecimal WAREHOUSE_LON = new BigDecimal("-3.7038");

    @Transactional
    public Route optimizeRoute(List<Long> orderIds, Long truckId, Long driverId) {
        // Obtener datos de pedidos desde orders-service
        List<OrderData> orders = getOrdersData(orderIds);

        if (orders.isEmpty()) {
            throw new RuntimeException("No orders found for optimization");
        }

        // Algoritmo Nearest Neighbor
        List<RouteStop> optimizedStops = new ArrayList<>();
        Point currentPoint = new Point(WAREHOUSE_LAT, WAREHOUSE_LON);
        Set<OrderData> unvisited = new HashSet<>(orders);
        int sequence = 1;

        while (!unvisited.isEmpty()) {
            OrderData nearest = findNearest(currentPoint, unvisited);

            RouteStop stop = new RouteStop();
            stop.setOrderId(nearest.getId());
            stop.setStopSequence(sequence++);
            stop.setLatitude(nearest.getDeliveryLatitude());
            stop.setLongitude(nearest.getDeliveryLongitude());
            stop.setAddress(nearest.getDeliveryAddress());
            stop.setStatus(RouteStop.StopStatus.PENDIENTE);
            optimizedStops.add(stop);

            currentPoint = new Point(nearest.getDeliveryLatitude(), nearest.getDeliveryLongitude());
            unvisited.remove(nearest);
        }

        // Crear la ruta
        Route route = new Route();
        route.setRouteCode(generateRouteCode());
        route.setTruckId(truckId);
        route.setDriverId(driverId);
        route.setStatus(Route.RouteStatus.PLANIFICADA);
        route.setScheduledStart(LocalDateTime.now().plusHours(1));
        route.setTotalDistanceKm(calculateTotalDistance(optimizedStops));
        route.setCreatedAt(LocalDateTime.now());
        route.setUpdatedAt(LocalDateTime.now());

        // Guardar la ruta
        Route savedRoute = routeRepository.save(route);

        // Asociar stops a la ruta
        for (RouteStop stop : optimizedStops) {
            stop.setRoute(savedRoute);
        }
        savedRoute.setStops(optimizedStops);

        return routeRepository.save(savedRoute);
    }

    private OrderData findNearest(Point from, Set<OrderData> orders) {
        return orders.stream()
                .min((o1, o2) -> Double.compare(
                        distance(from, new Point(o1.getDeliveryLatitude(), o1.getDeliveryLongitude())),
                        distance(from, new Point(o2.getDeliveryLatitude(), o2.getDeliveryLongitude()))
                ))
                .orElse(null);
    }

    private double distance(Point p1, Point p2) {
        // Fórmula de Haversine para calcular distancia entre dos puntos GPS
        double lat1 = Math.toRadians(p1.getLat().doubleValue());
        double lon1 = Math.toRadians(p1.getLon().doubleValue());
        double lat2 = Math.toRadians(p2.getLat().doubleValue());
        double lon2 = Math.toRadians(p2.getLon().doubleValue());

        double dlon = lon2 - lon1;
        double dlat = lat2 - lat1;

        double a = Math.pow(Math.sin(dlat / 2), 2) +
                Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(dlon / 2), 2);
        double c = 2 * Math.asin(Math.sqrt(a));

        return 6371 * c; // Radio de la Tierra en km
    }

    private BigDecimal calculateTotalDistance(List<RouteStop> stops) {
        if (stops.isEmpty()) {
            return BigDecimal.ZERO;
        }

        double totalDistance = 0.0;
        Point previous = new Point(WAREHOUSE_LAT, WAREHOUSE_LON);

        for (RouteStop stop : stops) {
            Point current = new Point(stop.getLatitude(), stop.getLongitude());
            totalDistance += distance(previous, current);
            previous = current;
        }

        // Añadir distancia de vuelta al almacén
        totalDistance += distance(previous, new Point(WAREHOUSE_LAT, WAREHOUSE_LON));

        return new BigDecimal(totalDistance).setScale(2, BigDecimal.ROUND_HALF_UP);
    }

    private List<OrderData> getOrdersData(List<Long> orderIds) {
        List<OrderData> orders = new ArrayList<>();

        try {
            List<ServiceInstance> instances = discoveryClient.getInstances("orders-service");

            if (instances != null && !instances.isEmpty()) {
                ServiceInstance instance = instances.get(0);
                URI uri = instance.getUri();
                RestTemplate restTemplate = new RestTemplate();

                for (Long orderId : orderIds) {
                    String url = uri + "/orders/" + orderId;
                    try {
                        Map<String, Object> orderMap = restTemplate.getForObject(url, Map.class);
                        if (orderMap != null) {
                            OrderData order = new OrderData();
                            order.setId(Long.valueOf(orderMap.get("id").toString()));
                            order.setDeliveryAddress(orderMap.get("deliveryAddress") != null ? orderMap.get("deliveryAddress").toString() : "");
                            order.setDeliveryLatitude(orderMap.get("deliveryLatitude") != null ? new BigDecimal(orderMap.get("deliveryLatitude").toString()) : WAREHOUSE_LAT);
                            order.setDeliveryLongitude(orderMap.get("deliveryLongitude") != null ? new BigDecimal(orderMap.get("deliveryLongitude").toString()) : WAREHOUSE_LON);
                            orders.add(order);
                        }
                    } catch (Exception e) {
                        System.err.println("Error fetching order " + orderId + ": " + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error connecting to orders-service: " + e.getMessage());
        }

        return orders;
    }

    private String generateRouteCode() {
        return "ROUTE-" + System.currentTimeMillis();
    }

    // Clase interna para representar un punto geográfico
    private static class Point {
        private final BigDecimal lat;
        private final BigDecimal lon;

        public Point(BigDecimal lat, BigDecimal lon) {
            this.lat = lat;
            this.lon = lon;
        }

        public BigDecimal getLat() {
            return lat;
        }

        public BigDecimal getLon() {
            return lon;
        }
    }

    // Clase interna para datos de pedidos
    private static class OrderData {
        private Long id;
        private String deliveryAddress;
        private BigDecimal deliveryLatitude;
        private BigDecimal deliveryLongitude;

        public Long getId() {
            return id;
        }

        public void setId(Long id) {
            this.id = id;
        }

        public String getDeliveryAddress() {
            return deliveryAddress;
        }

        public void setDeliveryAddress(String deliveryAddress) {
            this.deliveryAddress = deliveryAddress;
        }

        public BigDecimal getDeliveryLatitude() {
            return deliveryLatitude;
        }

        public void setDeliveryLatitude(BigDecimal deliveryLatitude) {
            this.deliveryLatitude = deliveryLatitude;
        }

        public BigDecimal getDeliveryLongitude() {
            return deliveryLongitude;
        }

        public void setDeliveryLongitude(BigDecimal deliveryLongitude) {
            this.deliveryLongitude = deliveryLongitude;
        }
    }
}
