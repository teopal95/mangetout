package com.mangetout.repository;

import com.mangetout.model.ItemStatus;
import com.mangetout.model.WishlistItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WishlistItemRepository extends JpaRepository<WishlistItem, Long> {
    List<WishlistItem> findByCategorySlug(String slug);
    List<WishlistItem> findByStatus(ItemStatus status);
    List<WishlistItem> findByCategorySlugAndStatus(String slug, ItemStatus status);
}
