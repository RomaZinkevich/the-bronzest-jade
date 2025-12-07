package com.bronzejade.game.service;

import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.repositories.RoomPlayerRepository;
import com.bronzejade.game.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoomPlayerService {
    private final RoomPlayerRepository roomPlayerRepository;
    private final UserRepository userRepository;

    public boolean isInRoom(UUID roomId, UUID userId) {
        // Get user from database
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check if user is in the room
        return roomPlayerRepository.existsByRoomIdAndUser(roomId, user);
    }
}
