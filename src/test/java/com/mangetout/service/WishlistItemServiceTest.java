package com.mangetout.service;

import com.mangetout.exception.NotFoundException;
import com.mangetout.model.Category;
import com.mangetout.model.ItemStatus;
import com.mangetout.model.User;
import com.mangetout.model.WishlistItem;
import com.mangetout.repository.CategoryRepository;
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

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class WishlistItemServiceTest {

    @Mock WishlistItemRepository wishlistItemRepository;
    @Mock CategoryRepository categoryRepository;
    @Mock UserRepository userRepository;
    @Mock LinkPreviewService linkPreviewService;

    @InjectMocks WishlistItemService service;

    private User user;
    private Category category;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken("alice@test.com", null, List.of())
        );

        user = new User();
        user.setId("user-1");
        user.setUsername("alice");
        user.setEmail("alice@test.com");
        user.setCoupleId("couple-1");

        category = new Category("cat-1", "Movies", "movies", "🎬");

        when(userRepository.findByEmail("alice@test.com")).thenReturn(Optional.of(user));
    }

    // --- findAll ---

    @Test
    void findAll_returnsCoupleItems() {
        WishlistItem item = itemWithCouple("couple-1");
        when(wishlistItemRepository.findByCoupleId("couple-1")).thenReturn(List.of(item));

        List<WishlistItem> result = service.findAll(null, null);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCoupleId()).isEqualTo("couple-1");
    }

    @Test
    void findAll_withNoCoupleId_returnsSoloItems() {
        user.setCoupleId(null);

        WishlistItem soloItem = new WishlistItem();
        soloItem.setAddedById("user-1");
        soloItem.setCategory(category);
        when(wishlistItemRepository.findByAddedById("user-1")).thenReturn(List.of(soloItem));

        List<WishlistItem> result = service.findAll(null, null);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getAddedById()).isEqualTo("user-1");
    }

    @Test
    void findAll_filtersByCategoryAndStatus() {
        WishlistItem item = itemWithCouple("couple-1");
        when(wishlistItemRepository.findByCoupleIdAndCategory_SlugAndStatus("couple-1", "movies", ItemStatus.WANTED))
                .thenReturn(List.of(item));

        List<WishlistItem> result = service.findAll("movies", ItemStatus.WANTED);

        assertThat(result).hasSize(1);
    }

    // --- create ---

    @Test
    void create_setsFieldsFromSecurityContext() {
        WishlistItem incoming = new WishlistItem();
        incoming.setTitle("Inception");
        incoming.setCategory(category);

        when(categoryRepository.findById("cat-1")).thenReturn(Optional.of(category));
        when(wishlistItemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        WishlistItem saved = service.create(incoming);

        assertThat(saved.getCoupleId()).isEqualTo("couple-1");
        assertThat(saved.getAddedById()).isEqualTo("user-1");
        assertThat(saved.getAddedByUsername()).isEqualTo("alice");
    }

    @Test
    void create_withNoCoupleId_createsSoloItem() {
        user.setCoupleId(null);

        WishlistItem incoming = new WishlistItem();
        incoming.setTitle("Inception");
        incoming.setCategory(category);

        when(categoryRepository.findById("cat-1")).thenReturn(Optional.of(category));
        when(wishlistItemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        WishlistItem saved = service.create(incoming);

        assertThat(saved.getCoupleId()).isNull();
        assertThat(saved.getAddedById()).isEqualTo("user-1");
    }

    @Test
    void create_withInvalidCategory_throws() {
        WishlistItem incoming = new WishlistItem();
        incoming.setTitle("Inception");
        incoming.setCategory(category);

        when(categoryRepository.findById("cat-1")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.create(incoming))
                .isInstanceOf(NotFoundException.class);
    }

    // --- findById ---

    @Test
    void findById_wrongCouple_throws() {
        WishlistItem item = itemWithCouple("other-couple");
        when(wishlistItemRepository.findById("item-1")).thenReturn(Optional.of(item));

        assertThatThrownBy(() -> service.findById("item-1"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Access denied");
    }

    @Test
    void findById_notFound_throws() {
        when(wishlistItemRepository.findById("item-1")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById("item-1"))
                .isInstanceOf(NotFoundException.class);
    }

    // --- updateStatus ---

    @Test
    void updateStatus_sameCouple_succeeds() {
        WishlistItem item = itemWithCouple("couple-1");
        item.setId("item-1");
        when(wishlistItemRepository.findById("item-1")).thenReturn(Optional.of(item));
        when(wishlistItemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        WishlistItem result = service.updateStatus("item-1", ItemStatus.DONE);

        assertThat(result.getStatus()).isEqualTo(ItemStatus.DONE);
    }

    // --- delete ---

    @Test
    void delete_sameCouple_succeeds() {
        WishlistItem item = itemWithCouple("couple-1");
        item.setId("item-1");
        when(wishlistItemRepository.findById("item-1")).thenReturn(Optional.of(item));

        service.delete("item-1");

        verify(wishlistItemRepository).deleteById("item-1");
    }

    // --- helpers ---

    private WishlistItem itemWithCouple(String coupleId) {
        WishlistItem item = new WishlistItem();
        item.setCoupleId(coupleId);
        item.setCategory(category);
        item.setStatus(ItemStatus.WANTED);
        return item;
    }
}
