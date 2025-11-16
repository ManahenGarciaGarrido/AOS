package com.azulejosromu.products_service.repository;

import com.azulejosromu.products_service.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {
    Optional<Category> findByCode(String code);
    List<Category> findByParentId(Long parentId);
    List<Category> findByActiveTrue();
}
