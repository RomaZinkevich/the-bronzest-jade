package com.bronzejade.game.repositories;

import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.domain.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoomPlayerRepository extends JpaRepository<RoomPlayer, UUID> {
    List<RoomPlayer> findByRoomId(UUID roomId);
    Optional<RoomPlayer> findByRoomIdAndUser(UUID roomId, User user);
    boolean existsByRoomIdAndUser(UUID roomId, User user);
    long countByRoomId(UUID roomId);
}
