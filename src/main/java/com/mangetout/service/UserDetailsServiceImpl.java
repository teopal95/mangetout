package com.mangetout.service;

import com.mangetout.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

// Spring Security needs to know HOW to load a user during authentication.
// This class implements that interface, telling Spring: "to look up a user,
// search the database by email, then wrap them in a Spring Security User object."
//
// Even though the interface is called "UserDetailsService", in our app
// the "username" we pass around is actually the user's email address.
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository; // Access to the users table

    // Spring Security calls this method when it needs to verify a login.
    // The "username" parameter is the email the user typed in the login form.
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userRepository.findByEmail(email)
                .map(user -> new org.springframework.security.core.userdetails.User(
                        user.getEmail(),    // We use email as the "username" in Spring Security
                        user.getPassword(), // The BCrypt-hashed password (Spring checks it automatically)
                        List.of(new SimpleGrantedAuthority("ROLE_USER")) // Every user has ROLE_USER
                ))
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
    }
}
