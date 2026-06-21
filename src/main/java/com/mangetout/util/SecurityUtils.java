package com.mangetout.util;

import org.springframework.security.core.context.SecurityContextHolder;

public class SecurityUtils {

    private SecurityUtils() {}

    // Returns the email of the currently authenticated user.
    // The JWT filter sets this as the authentication principal name.
    public static String getCurrentUserEmail() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }
}
