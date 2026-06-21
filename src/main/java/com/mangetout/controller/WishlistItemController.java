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
@RequiredArgsConstructor
public class WishlistItemController {

    private final WishlistItemService wishlistItemService;

    @GetMapping
    public List<WishlistItem> getAll(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) ItemStatus status) {
        return wishlistItemService.findAll(category, status);
    }

    @GetMapping("/{id}")
    public WishlistItem getById(@PathVariable String id) {
        return wishlistItemService.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public WishlistItem create(@Valid @RequestBody WishlistItem item) {
        return wishlistItemService.create(item);
    }

    @PutMapping("/{id}")
    public WishlistItem update(@PathVariable String id, @Valid @RequestBody WishlistItem item) {
        return wishlistItemService.update(id, item);
    }

    @PatchMapping("/{id}/status")
    public WishlistItem updateStatus(@PathVariable String id, @RequestParam ItemStatus status) {
        return wishlistItemService.updateStatus(id, status);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id) {
        wishlistItemService.delete(id);
    }
}
