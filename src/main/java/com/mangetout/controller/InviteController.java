package com.mangetout.controller;

import com.mangetout.dto.CoupleStatusResponse;
import com.mangetout.dto.InviteResponse;
import com.mangetout.service.InviteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/invite")
@RequiredArgsConstructor
public class InviteController {

    private final InviteService inviteService;

    @PostMapping("/generate")
    public InviteResponse generate() { return inviteService.generateInvite(); }

    @GetMapping(value = "/qr", produces = MediaType.IMAGE_PNG_VALUE)
    public byte[] qrCode() { return inviteService.generateQrCode(); }

    @PostMapping("/accept/{token}")
    public void accept(@PathVariable String token) { inviteService.acceptInvite(token); }

    @GetMapping("/status")
    public CoupleStatusResponse status() { return inviteService.getCoupleStatus(); }
}
