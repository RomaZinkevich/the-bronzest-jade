package com.bronzejade.game.service;

import com.bronzejade.game.security.ApiUserDetails;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with username: " + username));
        return new ApiUserDetails(user.getId(), user.getUsername(), user.getPassword());
    }

    public UserDetails loadUserById(String id) throws UsernameNotFoundException {
        User user = userRepository.findById(UUID.fromString(id))
                .orElseThrow(() -> new UsernameNotFoundException("User not found with id: " + id));
        return new ApiUserDetails(user.getId(), user.getUsername(), user.getPassword());
    }
}