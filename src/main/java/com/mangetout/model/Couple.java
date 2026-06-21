package com.mangetout.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "couples")
@Data
@NoArgsConstructor
public class Couple {

    @Id
    private String id;

    private String user1Id;

    // Null until a partner accepts the invite
    private String user2Id;

    // UUID token embedded in the QR code; cleared after use
    private String inviteToken;
    private LocalDateTime inviteTokenExpiry;

    @CreatedDate
    private LocalDateTime createdAt;

    public boolean isComplete() {
        return user1Id != null && user2Id != null;
    }

    public boolean isTokenExpired() {
        return inviteTokenExpiry == null || LocalDateTime.now().isAfter(inviteTokenExpiry);
    }
}
