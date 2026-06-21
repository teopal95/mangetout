package com.mangetout.service;

import com.mangetout.dto.CoupleStatusResponse;
import com.mangetout.dto.InviteResponse;
import com.mangetout.model.Couple;
import com.mangetout.model.User;
import com.mangetout.repository.CoupleRepository;
import com.mangetout.repository.UserRepository;
import com.mangetout.repository.WishlistItemRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class InviteServiceTest {

    @Mock CoupleRepository coupleRepository;
    @Mock UserRepository userRepository;
    @Mock WishlistItemRepository wishlistItemRepository;

    @InjectMocks InviteService service;

    private User alice;
    private User bob;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken("alice@test.com", null, List.of())
        );

        alice = new User();
        alice.setId("user-alice");
        alice.setUsername("alice");
        alice.setEmail("alice@test.com");

        bob = new User();
        bob.setId("user-bob");
        bob.setUsername("bob");
        bob.setEmail("bob@test.com");

        when(userRepository.findByEmail("alice@test.com")).thenReturn(Optional.of(alice));
        when(wishlistItemRepository.findByAddedByIdAndCoupleIdIsNull(any())).thenReturn(Collections.emptyList());
    }

    // --- generateInvite ---

    @Test
    void generateInvite_newUser_createsCouple() {
        Couple savedCouple = new Couple();
        savedCouple.setId("couple-1");
        savedCouple.setUser1Id("user-alice");
        savedCouple.setInviteToken("some-token");
        savedCouple.setInviteTokenExpiry(LocalDateTime.now().plusDays(7));

        when(coupleRepository.save(any())).thenReturn(savedCouple);

        InviteResponse response = service.generateInvite();

        assertThat(response.token()).isEqualTo("some-token");
        assertThat(response.inviteUrl()).contains("some-token");
        verify(userRepository).save(alice);
    }

    @Test
    void generateInvite_alreadyComplete_throws() {
        alice.setCoupleId("couple-1");

        Couple couple = new Couple();
        couple.setId("couple-1");
        couple.setUser1Id("user-alice");
        couple.setUser2Id("user-bob");

        when(coupleRepository.findById("couple-1")).thenReturn(Optional.of(couple));

        assertThatThrownBy(() -> service.generateInvite())
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("already have a partner");
    }

    // --- acceptInvite ---

    @Test
    void acceptInvite_validToken_linksBob() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken("bob@test.com", null, List.of())
        );
        when(userRepository.findByEmail("bob@test.com")).thenReturn(Optional.of(bob));

        Couple couple = new Couple();
        couple.setId("couple-1");
        couple.setUser1Id("user-alice");
        couple.setInviteToken("valid-token");
        couple.setInviteTokenExpiry(LocalDateTime.now().plusDays(1));

        when(coupleRepository.findByInviteToken("valid-token")).thenReturn(Optional.of(couple));

        service.acceptInvite("valid-token");

        assertThat(couple.getUser2Id()).isEqualTo("user-bob");
        assertThat(couple.getInviteToken()).isNull();
        verify(userRepository).save(bob);
    }

    @Test
    void acceptInvite_ownToken_throws() {
        Couple couple = new Couple();
        couple.setId("couple-1");
        couple.setUser1Id("user-alice");
        couple.setInviteToken("token");
        couple.setInviteTokenExpiry(LocalDateTime.now().plusDays(1));

        when(coupleRepository.findByInviteToken("token")).thenReturn(Optional.of(couple));

        assertThatThrownBy(() -> service.acceptInvite("token"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("own invite");
    }

    @Test
    void acceptInvite_expiredToken_throws() {
        Couple couple = new Couple();
        couple.setUser1Id("user-someone-else");
        couple.setInviteToken("old-token");
        couple.setInviteTokenExpiry(LocalDateTime.now().minusDays(1));

        when(coupleRepository.findByInviteToken("old-token")).thenReturn(Optional.of(couple));

        assertThatThrownBy(() -> service.acceptInvite("old-token"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("expired");
    }

    @Test
    void acceptInvite_alreadyUsed_throws() {
        Couple couple = new Couple();
        couple.setUser1Id("user-someone");
        couple.setUser2Id("user-other");
        couple.setInviteToken("used-token");
        couple.setInviteTokenExpiry(LocalDateTime.now().plusDays(1));

        when(coupleRepository.findByInviteToken("used-token")).thenReturn(Optional.of(couple));

        assertThatThrownBy(() -> service.acceptInvite("used-token"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("already been used");
    }

    @Test
    void acceptInvite_userAlreadyLinkedToCompleteCouple_throws() {
        alice.setCoupleId("existing-couple");

        // alice is already in a COMPLETE couple
        Couple existingComplete = new Couple();
        existingComplete.setId("existing-couple");
        existingComplete.setUser1Id("user-alice");
        existingComplete.setUser2Id("user-bob");

        when(coupleRepository.findById("existing-couple")).thenReturn(Optional.of(existingComplete));

        Couple newCouple = new Couple();
        newCouple.setUser1Id("user-someone-else");
        newCouple.setInviteToken("token");
        newCouple.setInviteTokenExpiry(LocalDateTime.now().plusDays(1));

        when(coupleRepository.findByInviteToken("token")).thenReturn(Optional.of(newCouple));

        assertThatThrownBy(() -> service.acceptInvite("token"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("already linked");
    }

    @Test
    void acceptInvite_userWithPendingInvite_discardsPendingAndAccepts() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken("bob@test.com", null, List.of())
        );
        when(userRepository.findByEmail("bob@test.com")).thenReturn(Optional.of(bob));

        // Bob had generated his own invite (pending — no user2Id)
        bob.setCoupleId("bob-pending-couple");
        Couple bobPending = new Couple();
        bobPending.setId("bob-pending-couple");
        bobPending.setUser1Id("user-bob");
        when(coupleRepository.findById("bob-pending-couple")).thenReturn(Optional.of(bobPending));

        // Alice's invite that Bob will accept
        Couple aliceCouple = new Couple();
        aliceCouple.setId("couple-1");
        aliceCouple.setUser1Id("user-alice");
        aliceCouple.setInviteToken("alice-token");
        aliceCouple.setInviteTokenExpiry(LocalDateTime.now().plusDays(1));

        when(coupleRepository.findByInviteToken("alice-token")).thenReturn(Optional.of(aliceCouple));

        service.acceptInvite("alice-token");

        verify(coupleRepository).delete(bobPending); // pending invite was discarded
        assertThat(aliceCouple.getUser2Id()).isEqualTo("user-bob");
    }

    // --- getCoupleStatus ---

    @Test
    void getCoupleStatus_noCouple_returnsNotLinked() {
        CoupleStatusResponse status = service.getCoupleStatus();

        assertThat(status.hasPartner()).isFalse();
        assertThat(status.coupleId()).isNull();
    }

    @Test
    void getCoupleStatus_pendingInvite_returnsTokenAndNotLinked() {
        alice.setCoupleId("couple-1");

        Couple couple = new Couple();
        couple.setId("couple-1");
        couple.setUser1Id("user-alice");
        couple.setInviteToken("pending-token");

        when(coupleRepository.findById("couple-1")).thenReturn(Optional.of(couple));

        CoupleStatusResponse status = service.getCoupleStatus();

        assertThat(status.hasPartner()).isFalse();
        assertThat(status.coupleId()).isEqualTo("couple-1");
        assertThat(status.inviteToken()).isEqualTo("pending-token");
    }

    @Test
    void getCoupleStatus_linked_returnsPartnerUsername() {
        alice.setCoupleId("couple-1");

        Couple couple = new Couple();
        couple.setId("couple-1");
        couple.setUser1Id("user-alice");
        couple.setUser2Id("user-bob");

        when(coupleRepository.findById("couple-1")).thenReturn(Optional.of(couple));
        when(userRepository.findById("user-bob")).thenReturn(Optional.of(bob));

        CoupleStatusResponse status = service.getCoupleStatus();

        assertThat(status.hasPartner()).isTrue();
        assertThat(status.partnerUsername()).isEqualTo("bob");
    }
}
