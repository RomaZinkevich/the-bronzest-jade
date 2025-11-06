package com.bronzejade.game.repositories;

import com.bronzejade.game.domain.entities.GameAction;
import com.bronzejade.game.domain.entities.GameState;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GameActionRepository extends JpaRepository<GameAction, UUID> {
    Optional<GameAction> findByGameState_IdAndRoundNumber(UUID gameStateId, Integer roundNumber);
}
