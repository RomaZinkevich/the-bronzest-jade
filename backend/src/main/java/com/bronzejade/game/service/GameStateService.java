package com.bronzejade.game.service;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.TurnPhase;
import com.bronzejade.game.domain.entities.GameAction;
import com.bronzejade.game.domain.entities.GameState;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.repositories.*;
import jakarta.persistence.EntityNotFoundException;
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
    private final UserRepository userRepo;
    private final GameActionRepository gameActionRepository;

    @Transactional
    public void submitQuestion(String question, UUID roomId, UUID userId, UUID guestSessionId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Game state not found"));

        RoomPlayer player = getPlayerFromRoom(roomId, userId, guestSessionId);

        // Room should be in progress state in order to submit a question
        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new IllegalArgumentException("Room is not in progress");
        }
        if (!gameState.getTurnPlayer().getId().equals(player.getId())) {
            throw new IllegalArgumentException("Not user's turn to ask");
        }
        if (!gameState.getTurnPhase().equals(TurnPhase.ASKING)) {
            throw new IllegalArgumentException("Not in ASKING phase");
        }

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
    public void submitAnswer(String answer, UUID roomId, UUID userId, UUID guestSessionId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Game state not found"));

        RoomPlayer player = getPlayerFromRoom(roomId, userId, guestSessionId);

        // Room should be in progress state in order to submit an answer
        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new IllegalArgumentException("Room is not in progress");
        }

        /*
          Counterintuitive, but turn player shows who was asking a question during Asking phase
          So when it switches to Answer phase turn player doesn't change
          So turn player should not be equal to player who answered a question (current player)
         */
        if (gameState.getTurnPlayer().getId().equals(player.getId())) {
            throw new IllegalArgumentException("Not user's turn to answer");
        }

        if (!gameState.getTurnPhase().equals(TurnPhase.ANSWERING)) {
            throw new IllegalArgumentException("Not in ANSWERING phase");
        }

        GameAction gameAction = gameActionRepository
                .findByGameState_IdAndRoundNumber(gameState.getId(), gameState.getRoundNumber())
                .orElseThrow(() -> new EntityNotFoundException("Game action not found"));
        gameAction.setAnswer(answer);
        gameAction.setAnsweringPlayer(player);
        gameActionRepository.save(gameAction);

        gameState.setTurnPhase(TurnPhase.ASKING);

        // Finally switch turns
        gameState.setTurnPlayer(player);
        gameState.setRoundNumber(gameState.getRoundNumber() + 1);
        gameStateRepo.save(gameState);
    }

    private RoomPlayer getPlayerFromRoom(UUID roomId, UUID userId, UUID guestSessionId) {
        if (userId != null) {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found with id: " + userId));
            return roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        } else if (guestSessionId != null) {
            return roomPlayerRepo.findByRoomIdAndGuestSessionId(roomId, guestSessionId)
                    .orElseThrow(() -> new EntityNotFoundException("Guest player not found in room"));
        } else {
            throw new IllegalArgumentException("Either userId or guestSessionId must be provided");
        }
    }
}
