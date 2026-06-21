package com.mangetout.service;

import com.mangetout.model.Category;
import com.mangetout.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public List<Category> findAll() {
        return categoryRepository.findAll();
    }

    public Category findBySlug(String slug) {
        return categoryRepository.findBySlug(slug)
                .orElseThrow(() -> new IllegalArgumentException("Category not found: " + slug));
    }

    public Category create(Category category) {
        if (category.getName() == null || category.getName().isBlank()) {
            throw new IllegalArgumentException("Category name is required");
        }
        if (category.getSlug() == null || category.getSlug().isBlank()) {
            String slug = category.getName().toLowerCase()
                    .replaceAll("[^a-z0-9\\s]", "")
                    .trim()
                    .replaceAll("\\s+", "-");
            category.setSlug(slug);
        }
        if (categoryRepository.existsByName(category.getName())) {
            throw new IllegalArgumentException("A category named \"" + category.getName() + "\" already exists");
        }
        if (categoryRepository.existsBySlug(category.getSlug())) {
            throw new IllegalArgumentException("A category with slug \"" + category.getSlug() + "\" already exists");
        }
        return categoryRepository.save(category);
    }
}
