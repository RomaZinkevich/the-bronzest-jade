package com.bronzejade.game.service;

import com.bronzejade.game.repositories.RoomRepository;
import java.util.UUID;
import java.time.LocalDateTime;
import java.util.List;
import com.bronzejade.game.domain.entities.GameState;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.TurnPhase;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.transaction.annotation.Transactional;
import com.bronzejade.game.repositories.GameStateRepository;
import com.bronzejade.game.repositories.RoomPlayerRepository;
import com.bronzejade.game.domain.dtos.GuessCharacterResponse;
import com.bronzejade.game.domain.entities.Character;
import org.springframework.stereotype.Service;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.Room;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class GuessCharacterService{
    private final RoomRepository roomRepo;
    private final RoomPlayerRepository roomPlayerRepo;
    private final GameStateRepository gameStateRepo;

    @Transactional
    public GuessCharacterResponse guessCharacter(UUID roomId, UUID playerId, UUID guessedCharacterId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new IllegalArgumentException("Game is not in progress");
        }

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Game state not found"));

        RoomPlayer guessingPlayer = roomPlayerRepo.findByRoomIdAndUserId(roomId, playerId)
                .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));

        // I am making essentially three checks here which determine whether,
        // the player can guess or not

        // CHECK 1: Turn player must exist
        if (gameState.getTurnPlayer() == null) {
            throw new IllegalArgumentException("Turn player not set");
        }

        // CHECK 2: Must be the player's turn (who can guess?)
        if (!gameState.getTurnPlayer().getId().equals(guessingPlayer.getId())) {
            throw new IllegalArgumentException("Not user's turn to guess");
        }

        // CHECK 3: Must be ASKING phase (when they can guess?)
        if (!gameState.getTurnPhase().equals(TurnPhase.ASKING)) {
            throw new IllegalArgumentException("Not in ASKING phase");
        }

        // Filtering out the opponent player
        List<RoomPlayer> allPlayers = roomPlayerRepo.findByRoomId(roomId);
        RoomPlayer opponentPlayer = allPlayers.stream()
                .filter(p -> !p.getId().equals(guessingPlayer.getId()))
                .findFirst()
                .orElseThrow(() -> new EntityNotFoundException("Opponent not found"));

        // Validate the guessed character exists in the character set
        CharacterSet characterSet = room.getCharacterSet();
        Character guessedCharacter = characterSet.getCharacters().stream()
                .filter(c -> c.getId().equals(guessedCharacterId))
                .findFirst()
                .orElseThrow(() -> new EntityNotFoundException("Guessed character not found in character set"));

        // Get the opponent's actual character
        Character actualCharacter = opponentPlayer.getCharacterToGuess();
        if (actualCharacter == null) {
            throw new IllegalArgumentException("Opponent hasn't selected a character");
        }

        // Check if the guess is correct
        boolean isCorrect = actualCharacter.getId().equals(guessedCharacterId);

        GuessCharacterResponse response = GuessCharacterResponse.builder()
                .correct(isCorrect)
                .guessedCharacterId(guessedCharacter.getId())
                .guessedCharacterName(guessedCharacter.getName())
                .actualCharacterId(actualCharacter.getId())
                .actualCharacterName(actualCharacter.getName())
                .build();

        if (isCorrect) { // End the game if player guesses correctly
            room.setStatus(RoomStatus.FINISHED);
            room.setFinishedAt(LocalDateTime.now());
            gameState.setWinnerId(playerId);

            gameStateRepo.save(gameState);
            roomRepo.save(room);

            return response.toBuilder()
                    .gameEnded(true)
                    .winnerId(playerId)
                    .message("Correct! You've won the game!")
                    .build();
        }
        else{ // If its a wrong guess switch turns
            gameState.setTurnPlayer(opponentPlayer);
            gameState.setTurnPhase(TurnPhase.ASKING);
            gameStateRepo.save(gameState);

            return response.toBuilder()
                    .gameEnded(false)
                    .winnerId(null)
                    .message("Wrong guess! Turn passes to opponent.")
                    .build();
        }
    }
}