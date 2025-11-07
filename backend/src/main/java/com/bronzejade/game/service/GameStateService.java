package com.bronzejade.game.service;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.TurnPhase;
import com.bronzejade.game.domain.entities.GameAction;
import com.bronzejade.game.domain.entities.GameState;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.repositories.GameActionRepository;
import com.bronzejade.game.repositories.GameStateRepository;
import com.bronzejade.game.repositories.RoomPlayerRepository;
import com.bronzejade.game.repositories.RoomRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GameStateService {

    private final RoomRepository roomRepo;
    private final GameStateRepository gameStateRepo;
    private final RoomPlayerRepository roomPlayerRepo;
    private final GameActionRepository gameActionRepository;

    @Transactional
    public void submitQuestion(String question, UUID roomId, UUID playerId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found with id: " + roomId));

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new RuntimeException("Game state not found"));

        RoomPlayer player = roomPlayerRepo.findByRoomIdAndUserId(roomId, playerId)
                .orElseThrow(() -> new RuntimeException("Turn player not found in room"));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) throw new RuntimeException("Room is not in progress");
        if (gameState.getTurnPlayer().getId() != player.getId()) throw new RuntimeException("Not permitted");
        if (!gameState.getTurnPhase().equals(TurnPhase.ASKING)) throw new RuntimeException("Not permitted");

        GameAction gameAction = new GameAction();
        gameAction.setGameState(gameState);
        gameAction.setAskingPlayer(player);
        gameAction.setQuestion(question);
        gameAction.setRoundNumber(gameState.getRoundNumber());

        gameActionRepository.save(gameAction);

        gameState.setTurnPhase(TurnPhase.ANSWERING);
        gameStateRepo.save(gameState);
    }

    @Transactional
    public void submitAnswer(String answer, UUID roomId, UUID playerId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found with id: " + roomId));

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new RuntimeException("Game state not found"));

        RoomPlayer player = roomPlayerRepo.findByRoomIdAndUserId(roomId, playerId)
                .orElseThrow(() -> new RuntimeException("Turn player not found in room"));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) throw new RuntimeException("Room is not in progress");
        if (gameState.getTurnPlayer().getId() == player.getId()) throw new RuntimeException("Not permitted");
        if (!gameState.getTurnPhase().equals(TurnPhase.ANSWERING)) throw new RuntimeException("Not permitted");

        GameAction gameAction = gameActionRepository
                .findByGameState_IdAndRoundNumber(gameState.getId(), gameState.getRoundNumber())
                .orElseThrow(() -> new RuntimeException("Game action not found"));
        gameAction.setAnswer(answer);
        gameAction.setAnsweringPlayer(player);
        gameActionRepository.save(gameAction);

        gameState.setTurnPhase(TurnPhase.ASKING);
        gameState.setTurnPlayer(player);
        gameState.setRoundNumber(gameState.getRoundNumber() + 1);
        gameStateRepo.save(gameState);
    }
}
