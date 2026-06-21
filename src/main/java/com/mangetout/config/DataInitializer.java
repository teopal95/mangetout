package com.mangetout.config;

import com.mangetout.model.Category;
import com.mangetout.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class DataInitializer implements ApplicationRunner {

    private final CategoryRepository categoryRepository;

    @Override
    public void run(ApplicationArguments args) {
        // Only seed if the table is empty to avoid duplicates on restart with persistent data.
        if (categoryRepository.count() == 0) {
            categoryRepository.saveAll(List.of(
                new Category(null, "Recipes",    "recipes",    "🍽️"),
                new Category(null, "Places",     "places",     "📍"),
                new Category(null, "Movies",     "movies",     "🎬"),
                new Category(null, "Furniture",  "furniture",  "🛋️"),
                new Category(null, "Books",      "books",      "📚"),
                new Category(null, "Activities", "activities", "🎯")
            ));
        }
    }
}
