package com.mangetout.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    private String id;

    @NotBlank
    @Indexed(unique = true)
    private String username;

    @Email
    @NotBlank
    @Indexed(unique = true)
    private String email;

    @NotBlank
    @JsonIgnore
    private String password;

    private String avatarUrl;

    // References the shared Couple document; null until the user is linked to a partner
    private String coupleId;

    @CreatedDate
    private LocalDateTime createdAt;
}
