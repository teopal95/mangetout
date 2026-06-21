package com.mangetout.repository;

import com.mangetout.model.ItemStatus;
import com.mangetout.model.WishlistItem;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface WishlistItemRepository extends MongoRepository<WishlistItem, String> {

    // Coupled users — scoped to the shared couple
    List<WishlistItem> findByCoupleId(String coupleId);
    List<WishlistItem> findByCoupleIdAndCategory_Slug(String coupleId, String slug);
    List<WishlistItem> findByCoupleIdAndStatus(String coupleId, ItemStatus status);
    List<WishlistItem> findByCoupleIdAndCategory_SlugAndStatus(String coupleId, String slug, ItemStatus status);

    // Solo users — scoped to the individual who added them
    List<WishlistItem> findByAddedById(String addedById);
    List<WishlistItem> findByAddedByIdAndCategory_Slug(String addedById, String slug);
    List<WishlistItem> findByAddedByIdAndStatus(String addedById, ItemStatus status);
    List<WishlistItem> findByAddedByIdAndCategory_SlugAndStatus(String addedById, String slug, ItemStatus status);

    // Couple linking
    List<WishlistItem> findByAddedByIdAndCoupleIdIsNull(String addedById);
    void deleteByAddedByIdAndCoupleIdIsNull(String addedById);
}
