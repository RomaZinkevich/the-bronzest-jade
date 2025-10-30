package com.bronzejade.game.service;

import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.repositories.RoomPlayerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoomPlayerService {
    private final RoomPlayerRepository roomPlayerRepository;

    public boolean isInRoom(UUID roomId, UUID playerId) {
        Optional<RoomPlayer> player = roomPlayerRepository.findByRoomIdAndUserId(roomId, playerId);
        return player.isPresent();
    }
}
