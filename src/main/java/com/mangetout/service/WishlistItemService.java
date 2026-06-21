package com.mangetout.service;

import com.mangetout.exception.NotFoundException;
import com.mangetout.model.ItemStatus;
import com.mangetout.model.User;
import com.mangetout.model.WishlistItem;
import com.mangetout.repository.CategoryRepository;
import com.mangetout.repository.UserRepository;
import com.mangetout.repository.WishlistItemRepository;
import com.mangetout.util.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class WishlistItemService {

    private final WishlistItemRepository wishlistItemRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final LinkPreviewService linkPreviewService;

    public List<WishlistItem> findAll(String categorySlug, ItemStatus status) {
        User user = getCurrentUser();
        if (user.getCoupleId() != null) {
            return findByCoupleScope(user.getCoupleId(), categorySlug, status);
        }
        return findBySoloScope(user.getId(), categorySlug, status);
    }

    public WishlistItem findById(String id) {
        WishlistItem item = wishlistItemRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Item not found: " + id));
        requireAccess(item);
        return item;
    }

    public WishlistItem create(WishlistItem item) {
        User user = getCurrentUser();

        // coupleId may be null for solo users — that's intentional
        item.setCoupleId(user.getCoupleId());
        item.setAddedById(user.getId());
        item.setAddedByUsername(user.getUsername());

        item.setCategory(categoryRepository.findById(item.getCategory().getId())
                .orElseThrow(() -> new NotFoundException("Category not found: " + item.getCategory().getId())));

        if (item.getExternalUrl() != null && !item.getExternalUrl().isBlank()) {
            item.setLinkPreviewImageUrl(linkPreviewService.fetchOgImage(item.getExternalUrl()));
            item.setLinkPreviewTitle(linkPreviewService.fetchOgTitle(item.getExternalUrl()));
        }

        return wishlistItemRepository.save(item);
    }

    public WishlistItem update(String id, WishlistItem updated) {
        WishlistItem existing = findById(id);
        existing.setTitle(updated.getTitle());
        existing.setDescription(updated.getDescription());
        existing.setNotes(updated.getNotes());
        existing.setImageUrl(updated.getImageUrl());
        existing.setExternalUrl(updated.getExternalUrl());
        existing.setCategory(categoryRepository.findById(updated.getCategory().getId())
                .orElseThrow(() -> new NotFoundException("Category not found: " + updated.getCategory().getId())));
        return wishlistItemRepository.save(existing);
    }

    public WishlistItem updateStatus(String id, ItemStatus status) {
        WishlistItem item = findById(id);
        item.setStatus(status);
        return wishlistItemRepository.save(item);
    }

    public void delete(String id) {
        findById(id);
        wishlistItemRepository.deleteById(id);
    }

    // -------------------------------------------------------------------------

    private List<WishlistItem> findByCoupleScope(String coupleId, String categorySlug, ItemStatus status) {
        if (categorySlug != null && status != null) {
            return wishlistItemRepository.findByCoupleIdAndCategory_SlugAndStatus(coupleId, categorySlug, status);
        }
        if (categorySlug != null) return wishlistItemRepository.findByCoupleIdAndCategory_Slug(coupleId, categorySlug);
        if (status != null)       return wishlistItemRepository.findByCoupleIdAndStatus(coupleId, status);
        return wishlistItemRepository.findByCoupleId(coupleId);
    }

    private List<WishlistItem> findBySoloScope(String userId, String categorySlug, ItemStatus status) {
        if (categorySlug != null && status != null) {
            return wishlistItemRepository.findByAddedByIdAndCategory_SlugAndStatus(userId, categorySlug, status);
        }
        if (categorySlug != null) return wishlistItemRepository.findByAddedByIdAndCategory_Slug(userId, categorySlug);
        if (status != null)       return wishlistItemRepository.findByAddedByIdAndStatus(userId, status);
        return wishlistItemRepository.findByAddedById(userId);
    }

    private void requireAccess(WishlistItem item) {
        User user = getCurrentUser();
        boolean allowed = user.getCoupleId() != null
                ? user.getCoupleId().equals(item.getCoupleId())
                : user.getId().equals(item.getAddedById());
        if (!allowed) {
            throw new IllegalArgumentException("Access denied: this item does not belong to you.");
        }
    }

    private User getCurrentUser() {
        String email = SecurityUtils.getCurrentUserEmail();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
    }
}
