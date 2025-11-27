package com.bronzejade.game.service;

import com.bronzejade.game.domain.dtos.AuthResponse;
import com.bronzejade.game.domain.dtos.LoginRequest;
import com.bronzejade.game.domain.dtos.RegisterRequest;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.jwtSetup.JwtUtil;
import com.bronzejade.game.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    public AuthResponse register(RegisterRequest request) {
        // Check if username or email already exist
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username already exists");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        // Create new user
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .build();

        User savedUser = userRepository.save(user);

        // Generate JWT token
        String token = jwtUtil.generateToken(savedUser.getId());

        return new AuthResponse(token, savedUser.getId(), savedUser.getUsername());
    }

    public AuthResponse login(LoginRequest request) {
        // Authenticate user
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getUsername(),
                        request.getPassword()
                )
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);

        User user = (User) authentication.getPrincipal();

        String token = jwtUtil.generateToken(user.getId());

        return new AuthResponse(token, user.getId(), user.getUsername());
    }

    public AuthResponse createGuestUser() {
        UUID guestSessionId = UUID.randomUUID();

        User guestUser = User.builder()
                .username("guest_" + guestSessionId.toString().substring(0, 8))
                .email(null)
                .password("")
                .createdAt(LocalDateTime.now())
                .build();

        User savedUser = userRepository.save(guestUser);

        String token = jwtUtil.generateToken(savedUser.getId());

        return new AuthResponse(token, savedUser.getId(), savedUser.getUsername());
    }

    public boolean validateToken(String token) {
        try {
            UUID userId = jwtUtil.validateTokenAndGetUserId(token);
            return userRepository.existsById(userId);
        } catch (Exception e) {
            return false;
        }
    }
}