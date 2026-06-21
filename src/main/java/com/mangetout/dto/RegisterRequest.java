package com.mangetout.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// This DTO holds the data the Flutter app sends when a user creates a new account.
// The @Valid annotation in the controller tells Spring to check these rules before proceeding.
// If any rule fails, Spring sends back a 400 error automatically — no manual checks needed.
//
// Example JSON body:
// { "username": "teo95", "email": "teo@example.com", "password": "secret123" }
public record RegisterRequest(
        @NotBlank String username, // Required — the display name (e.g. "teo95")
        @NotBlank @Email String email, // Required — must be a valid email format
        @NotBlank @Size(min = 6, message = "Password must be at least 6 characters") String password
        // Required — must be 6+ characters long for basic security
) {}
