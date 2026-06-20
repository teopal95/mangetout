package com.mangetout.service;

import com.mangetout.model.ItemStatus;
import com.mangetout.model.WishlistItem;
import com.mangetout.repository.WishlistItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class WishlistItemService {

    private final WishlistItemRepository wishlistItemRepository;

    public List<WishlistItem> findAll() {
        return wishlistItemRepository.findAll();
    }

    public List<WishlistItem> findByCategory(String slug) {
        return wishlistItemRepository.findByCategorySlug(slug);
    }

    public List<WishlistItem> findByStatus(ItemStatus status) {
        return wishlistItemRepository.findByStatus(status);
    }

    public List<WishlistItem> findByCategoryAndStatus(String slug, ItemStatus status) {
        return wishlistItemRepository.findByCategorySlugAndStatus(slug, status);
    }

    public WishlistItem findById(Long id) {
        return wishlistItemRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Item not found: " + id));
    }

    public WishlistItem create(WishlistItem item) {
        return wishlistItemRepository.save(item);
    }

    public WishlistItem update(Long id, WishlistItem updated) {
        WishlistItem existing = findById(id);
        existing.setTitle(updated.getTitle());
        existing.setDescription(updated.getDescription());
        existing.setNotes(updated.getNotes());
        existing.setImageUrl(updated.getImageUrl());
        existing.setExternalUrl(updated.getExternalUrl());
        existing.setCategory(updated.getCategory());
        return wishlistItemRepository.save(existing);
    }

    public WishlistItem updateStatus(Long id, ItemStatus status) {
        WishlistItem item = findById(id);
        item.setStatus(status);
        return wishlistItemRepository.save(item);
    }

    public void delete(Long id) {
        wishlistItemRepository.deleteById(id);
    }
}
