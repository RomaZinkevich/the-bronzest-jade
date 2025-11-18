package com.bronzejade.game.repositories;

import com.bronzejade.game.domain.entities.RoomPlayer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoomPlayerRepository extends JpaRepository<RoomPlayer, UUID> {
    List<RoomPlayer> findByRoomId(UUID roomId);
    Optional<RoomPlayer> findByRoomIdAndUserId(UUID roomId, UUID userId);
    boolean existsByRoomIdAndUserId(UUID roomId, UUID userId);
    long countByRoomId(UUID roomId);

    RoomPlayer findByHost(boolean host);
}
