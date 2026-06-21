package com.mangetout.dto;

public record CoupleStatusResponse(
        boolean hasPartner,
        String partnerUsername,
        String coupleId,
        String inviteToken    // non-null only when couple exists but is not yet complete
) {}
