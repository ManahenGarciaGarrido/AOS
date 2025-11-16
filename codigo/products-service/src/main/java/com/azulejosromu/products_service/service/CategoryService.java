package com.azulejosromu.products_service.service;

import com.azulejosromu.products_service.model.Category;
import com.azulejosromu.products_service.repository.CategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class CategoryService {

    @Autowired
    private CategoryRepository categoryRepository;

    public List<Category> findAll() {
        return categoryRepository.findAll();
    }

    public Optional<Category> findById(Long id) {
        return categoryRepository.findById(id);
    }

    public Optional<Category> findByCode(String code) {
        return categoryRepository.findByCode(code);
    }

    public List<Category> findByParentId(Long parentId) {
        return categoryRepository.findByParentId(parentId);
    }

    public List<Category> findActiveCategories() {
        return categoryRepository.findByActiveTrue();
    }

    @Transactional
    public Category save(Category category) {
        category.setUpdatedAt(LocalDateTime.now());
        if (category.getId() == null) {
            category.setCreatedAt(LocalDateTime.now());
        }
        return categoryRepository.save(category);
    }

    @Transactional
    public void deleteById(Long id) {
        Category category = findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + id));
        category.setActive(false);
        category.setUpdatedAt(LocalDateTime.now());
        save(category);
    }
}
