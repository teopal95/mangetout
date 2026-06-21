package com.mangetout.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "wishlist_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WishlistItem {

    @Id
    private String id;

    @NotBlank
    private String title;

    private String description;
    private String notes;
    private String imageUrl;
    private String externalUrl;
    private String linkPreviewImageUrl;
    private String linkPreviewTitle;

    private ItemStatus status = ItemStatus.WANTED;

    // Category is embedded directly — idiomatic MongoDB (no join needed on read)
    @NotNull
    private Category category;

    // References the Couple this item belongs to — used for scoping all queries
    private String coupleId;

    // Store only id + username instead of embedding the full User document
    private String addedById;
    private String addedByUsername;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
