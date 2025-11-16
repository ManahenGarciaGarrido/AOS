package com.azulejosromu.products_service.service;

import com.azulejosromu.products_service.model.Product;
import com.azulejosromu.products_service.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    public List<Product> findAll() {
        return productRepository.findAll();
    }

    public Optional<Product> findById(Long id) {
        return productRepository.findById(id);
    }

    public Optional<Product> findByCode(String code) {
        return productRepository.findByCode(code);
    }

    public List<Product> findByCategoryId(Long categoryId) {
        return productRepository.findByCategoryId(categoryId);
    }

    public List<Product> findBySupplierId(Long supplierId) {
        return productRepository.findBySupplierId(supplierId);
    }

    public List<Product> findActiveProducts() {
        return productRepository.findByActiveTrue();
    }

    @Transactional
    public Product save(Product product) {
        product.setUpdatedAt(LocalDateTime.now());
        if (product.getId() == null) {
            product.setCreatedAt(LocalDateTime.now());
        }
        return productRepository.save(product);
    }

    @Transactional
    public void deleteById(Long id) {
        Product product = findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
        product.setActive(false);
        product.setUpdatedAt(LocalDateTime.now());
        save(product);
    }
}
