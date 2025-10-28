package com.bronzejade.game.repositories;

import com.bronzejade.game.domain.entities.GameState;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface GameStateRepository extends JpaRepository<GameState, UUID> {
    Optional<GameState> findByRoomId(UUID roomId);
    boolean existsByRoomId(UUID roomId);
}
