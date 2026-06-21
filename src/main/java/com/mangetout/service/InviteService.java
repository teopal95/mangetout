package com.mangetout.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.mangetout.dto.CoupleStatusResponse;
import com.mangetout.dto.InviteResponse;
import com.mangetout.exception.NotFoundException;
import com.mangetout.model.Couple;
import com.mangetout.model.User;
import com.mangetout.model.WishlistItem;
import com.mangetout.repository.CoupleRepository;
import com.mangetout.repository.UserRepository;
import com.mangetout.repository.WishlistItemRepository;
import com.mangetout.util.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class InviteService {

    private static final int TOKEN_VALID_DAYS = 7;
    private static final int QR_SIZE_PX = 300;

    private final CoupleRepository coupleRepository;
    private final UserRepository userRepository;
    private final WishlistItemRepository wishlistItemRepository;

    public InviteResponse generateInvite() {
        User user = getCurrentUser();

        Couple couple;
        if (user.getCoupleId() != null) {
            couple = coupleRepository.findById(user.getCoupleId())
                    .orElseThrow(() -> new IllegalStateException("Couple record not found for user " + user.getId()));
            if (couple.isComplete()) {
                throw new IllegalArgumentException("You already have a partner linked. Disconnect first to generate a new invite.");
            }
        } else {
            couple = new Couple();
            couple.setUser1Id(user.getId());
        }

        couple.setInviteToken(UUID.randomUUID().toString());
        couple.setInviteTokenExpiry(LocalDateTime.now().plusDays(TOKEN_VALID_DAYS));
        couple = coupleRepository.save(couple);

        if (user.getCoupleId() == null) {
            user.setCoupleId(couple.getId());
            userRepository.save(user);
        }

        return new InviteResponse(couple.getInviteToken(), "mangetout://invite/" + couple.getInviteToken(), couple.getInviteTokenExpiry());
    }

    public void acceptInvite(String token) {
        User currentUser = getCurrentUser();

        Couple couple = coupleRepository.findByInviteToken(token)
                .orElseThrow(() -> new NotFoundException("Invalid invite code. Make sure you copied it correctly."));

        if (couple.isTokenExpired()) {
            throw new IllegalArgumentException("This invite link has expired. Ask your partner to generate a new one.");
        }
        if (couple.isComplete()) {
            throw new IllegalArgumentException("This invite has already been used.");
        }
        if (couple.getUser1Id().equals(currentUser.getId())) {
            throw new IllegalArgumentException("You cannot accept your own invite.");
        }
        if (currentUser.getCoupleId() != null) {
            Couple existingCouple = coupleRepository.findById(currentUser.getCoupleId()).orElse(null);
            if (existingCouple != null && existingCouple.isComplete()) {
                throw new IllegalArgumentException("You are already linked to a partner.");
            }
            // Pending invite (no partner yet) — discard it so the user can accept this one
            if (existingCouple != null) {
                coupleRepository.delete(existingCouple);
            }
            currentUser.setCoupleId(null);
        }

        // Link the couple
        couple.setUser2Id(currentUser.getId());
        couple.setInviteToken(null);
        couple.setInviteTokenExpiry(null);
        coupleRepository.save(couple);

        currentUser.setCoupleId(couple.getId());
        userRepository.save(currentUser);

        // Delete accepter's solo items — they start fresh on the shared wishlist
        wishlistItemRepository.deleteByAddedByIdAndCoupleIdIsNull(currentUser.getId());

        // Migrate inviter's solo items into the shared couple scope
        List<WishlistItem> inviterSoloItems = wishlistItemRepository.findByAddedByIdAndCoupleIdIsNull(couple.getUser1Id());
        for (WishlistItem item : inviterSoloItems) {
            item.setCoupleId(couple.getId());
            wishlistItemRepository.save(item);
        }
    }

    public byte[] generateQrCode() {
        User user = getCurrentUser();
        if (user.getCoupleId() == null) {
            throw new IllegalArgumentException("Generate an invite first.");
        }

        Couple couple = coupleRepository.findById(user.getCoupleId())
                .orElseThrow(() -> new IllegalStateException("Couple record not found"));

        if (couple.getInviteToken() == null) {
            throw new IllegalArgumentException("No active invite. Generate one first.");
        }

        String deepLink = "mangetout://invite/" + couple.getInviteToken();
        try {
            BitMatrix matrix = new QRCodeWriter().encode(deepLink, BarcodeFormat.QR_CODE, QR_SIZE_PX, QR_SIZE_PX);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(matrix, "PNG", out);
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("QR code generation failed", e);
        }
    }

    public CoupleStatusResponse getCoupleStatus() {
        User user = getCurrentUser();
        if (user.getCoupleId() == null) {
            return new CoupleStatusResponse(false, null, null, null);
        }

        Couple couple = coupleRepository.findById(user.getCoupleId())
                .orElseThrow(() -> new IllegalStateException("Couple record not found"));

        if (!couple.isComplete()) {
            return new CoupleStatusResponse(false, null, couple.getId(), couple.getInviteToken());
        }

        String partnerId = couple.getUser1Id().equals(user.getId()) ? couple.getUser2Id() : couple.getUser1Id();
        User partner = userRepository.findById(partnerId)
                .orElseThrow(() -> new NotFoundException("Partner user not found"));

        return new CoupleStatusResponse(true, partner.getUsername(), couple.getId(), null);
    }

    private User getCurrentUser() {
        String email = SecurityUtils.getCurrentUserEmail();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
    }
}
