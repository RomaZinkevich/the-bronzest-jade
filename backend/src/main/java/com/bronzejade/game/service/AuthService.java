package com.bronzejade.game.service;

import com.bronzejade.game.domain.dtos.User.AuthResponse;
import com.bronzejade.game.domain.dtos.User.LoginRequest;
import com.bronzejade.game.domain.dtos.User.RegisterRequest;
import com.bronzejade.game.domain.dtos.User.UserDto;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.security.ApiUserDetails;
import com.bronzejade.game.security.JwtUtil;
import com.bronzejade.game.mapper.UserMapper;
import com.bronzejade.game.repositories.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final UserMapper userMapper;

    public AuthResponse register(RegisterRequest request) {
        // Check if username or email already exist
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("Username already exists");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already exists");
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

    @Transactional(readOnly = true)
    public UserDto getUserFromPrincipal(ApiUserDetails userDetails) {
        //For some reason I cant pass userDetails.getUser() directly due to LazyLoading issues
        //So I have to reinitialize user object from ID
        UUID userId = userDetails.getId();
        User user = userRepository.findById(userId).orElseThrow(EntityNotFoundException::new);

        return userMapper.toDto(user);
    }

    public AuthResponse login(LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getUsername(),
                            request.getPassword()
                    )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);

            ApiUserDetails user = (ApiUserDetails) authentication.getPrincipal();

            String token = jwtUtil.generateToken(user.getId());

            return new AuthResponse(token, user.getId(), user.getUsername());

        } catch (Exception e) {
            e.printStackTrace();
            throw e;  // or return an error response
        }
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

    public String getUsername(UUID userId) {
        User user = userRepository.findById(userId).orElseThrow(EntityNotFoundException::new);
        return user.getUsername();
    }
}