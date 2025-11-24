package com.bronzejade.game.service;

import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.entities.User;
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

    public boolean isInRoom(UUID roomId, UUID userId, UUID guestSessionId) {
        if (userId != null) {
            // Check for authenticated user
            Optional<User> user = userRepository.findById(userId);
            if (user.isEmpty()) {
                return false;
            }
            return roomPlayerRepository.existsByRoomIdAndUser(roomId, user.get());
        } else if (guestSessionId != null) {
            // Check for guest user
            return roomPlayerRepository.existsByRoomIdAndGuestSessionId(roomId, guestSessionId);
        }
        return false;
    }
}
