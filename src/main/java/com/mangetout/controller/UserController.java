package com.mangetout.controller;

import com.mangetout.dto.UpdateProfileRequest;
import com.mangetout.dto.UserProfileResponse;
import com.mangetout.model.User;
import com.mangetout.repository.UserRepository;
import com.mangetout.util.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public UserProfileResponse getProfile() {
        User user = getCurrentUser();
        return new UserProfileResponse(user.getUsername(), user.getEmail(), user.getAvatarUrl());
    }

    @PatchMapping("/me")
    public UserProfileResponse updateProfile(@RequestBody UpdateProfileRequest request) {
        User user = getCurrentUser();

        if (request.username() != null && !request.username().isBlank()) {
            user.setUsername(request.username().trim());
        }
        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl().isBlank() ? null : request.avatarUrl());
        }

        try {
            userRepository.save(user);
        } catch (DuplicateKeyException e) {
            throw new IllegalArgumentException("This username is already taken.");
        }

        return new UserProfileResponse(user.getUsername(), user.getEmail(), user.getAvatarUrl());
    }

    private User getCurrentUser() {
        String email = SecurityUtils.getCurrentUserEmail();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
    }
}
