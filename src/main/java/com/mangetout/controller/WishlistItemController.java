package com.mangetout.controller;

import com.mangetout.model.ItemStatus;
import com.mangetout.model.WishlistItem;
import com.mangetout.service.WishlistItemService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/items")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class WishlistItemController {

    private final WishlistItemService wishlistItemService;

    @GetMapping
    public List<WishlistItem> getAll(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) ItemStatus status) {
        if (category != null && status != null) {
            return wishlistItemService.findByCategoryAndStatus(category, status);
        }
        if (category != null) {
            return wishlistItemService.findByCategory(category);
        }
        if (status != null) {
            return wishlistItemService.findByStatus(status);
        }
        return wishlistItemService.findAll();
    }

    @GetMapping("/{id}")
    public WishlistItem getById(@PathVariable Long id) {
        return wishlistItemService.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public WishlistItem create(@Valid @RequestBody WishlistItem item) {
        return wishlistItemService.create(item);
    }

    @PutMapping("/{id}")
    public WishlistItem update(@PathVariable Long id, @Valid @RequestBody WishlistItem item) {
        return wishlistItemService.update(id, item);
    }

    @PatchMapping("/{id}/status")
    public WishlistItem updateStatus(@PathVariable Long id, @RequestParam ItemStatus status) {
        return wishlistItemService.updateStatus(id, status);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        wishlistItemService.delete(id);
    }
}
