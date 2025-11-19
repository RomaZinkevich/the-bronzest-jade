package com.bronzejade.game.service;

import com.bronzejade.game.entities.User;
import com.bronzejade.game.repositories.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.UUID;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        User user = userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userId));

        return new org.springframework.security.core.userdetails.User(
                user.getId().toString(),
                user.getPassword(),
                new ArrayList<>()
        );
    }
}