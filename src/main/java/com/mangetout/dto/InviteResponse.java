package com.mangetout.dto;

import java.time.LocalDateTime;

public record InviteResponse(
        String token,
        String inviteUrl,
        LocalDateTime expiresAt
) {}
