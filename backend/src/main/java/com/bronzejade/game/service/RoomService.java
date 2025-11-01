package com.bronzejade.game.service;

import com.bronzejade.game.domain.dtos.CreateRoomRequest;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.GameState;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.repositories.GameStateRepository;
import com.bronzejade.game.repositories.RoomPlayerRepository;
import com.bronzejade.game.repositories.RoomRepository;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.RoomStatus;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoomService {
    private final RoomRepository roomRepo;
    private final RoomPlayerRepository roomPlayerRepo;
    private final GameStateRepository gameStateRepo;
    private final CharacterSetService characterSetService;

    @Transactional
    public Room createRoom(CreateRoomRequest createRoomRequest) {
        CharacterSet characterSet = characterSetService.getCharacterSet(createRoomRequest.getCharacterSetId());
        UUID hostId =  createRoomRequest.getHostId();
        Room room = Room.builder()
                .hostId(hostId)
                .characterSet(characterSet)
                .maxPlayers(2)
                .status(RoomStatus.WAITING)
                .build();

        Room savedRoom = roomRepo.save(room);

        // Host is set as the first player to join the room
        RoomPlayer hostPlayer = RoomPlayer.builder()
                .room(savedRoom)
                .userId(hostId)
                .isHost(true)
                .isReady(false)
                .joinedAt(LocalDateTime.now())
                .build();

        roomPlayerRepo.save(hostPlayer);

        GameState gameState = GameState.builder()
                .room(savedRoom)
                .roundNumber(0)
                .build();

        gameStateRepo.save(gameState);

        return savedRoom;
    }

    public void deleteRoom(UUID id) {
        if (!roomRepo.existsById(id)) {
            throw new RuntimeException("Room not found with id: " + id);
        }
        roomRepo.deleteById(id);
    }

    public Room joinRoom(String roomCode, UUID playerId) {
        Room room = roomRepo.findByRoomCode(roomCode.toUpperCase())
                .orElseThrow(() -> new RuntimeException("Room could not be found"));

        UUID roomId = room.getId();

        if (room.getStatus() != RoomStatus.WAITING) {
            throw new RuntimeException("Room is not available for joining");
        }

        boolean playerAlreadyInRoom = roomPlayerRepo.existsByRoomIdAndUserId(roomId, playerId);
        if (playerAlreadyInRoom) {
            throw new RuntimeException("Player is already in the room");
        }

        // Checking if the room is full
        long currentPlayerCount = roomPlayerRepo.countByRoomId(roomId);
        if (currentPlayerCount >= room.getMaxPlayers()) {
            throw new RuntimeException("Room is full");
        }

        RoomPlayer newPlayer = RoomPlayer.builder()
                .room(room)
                .userId(playerId)
                .isHost(false)
                .isReady(false)
                .joinedAt(LocalDateTime.now())
                .build();

        roomPlayerRepo.save(newPlayer);

        long updatedPlayerCount = roomPlayerRepo.countByRoomId(roomId);
        if (updatedPlayerCount >= room.getMaxPlayers() && newPlayer.isReady()) {
            room.setStatus(RoomStatus.IN_PROGRESS);
        }
        return roomRepo.save(room);
    }

    public Room leaveRoom(UUID roomId, UUID playerId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found with id: " + roomId));

        RoomPlayer player = roomPlayerRepo.findByRoomIdAndUserId(roomId, playerId)
                .orElseThrow(() -> new RuntimeException("Player not found in room"));

        boolean wasHost = player.isHost();

        roomPlayerRepo.delete(player);

        if (wasHost) {
            List<RoomPlayer> remainingPlayers = roomPlayerRepo.findByRoomId(roomId);
            if (remainingPlayers.isEmpty()) { // if there are no players left after host leaves delete the room
                roomRepo.delete(room);
                return null;
            } else {
                RoomPlayer newHost = remainingPlayers.get(0);
                newHost.setHost(true); // Setting the remaining player as the new host
                roomPlayerRepo.save(newHost);
                room.setHostId(newHost.getUserId());
            }
        }

        // Update room status
        long remainingPlayerCount = roomPlayerRepo.countByRoomId(roomId);
        if (remainingPlayerCount < room.getMaxPlayers()) {
            room.setStatus(RoomStatus.WAITING);
        }

        return roomRepo.save(room);
    }

    public RoomPlayer togglePlayerReady(UUID roomId, UUID playerId) {
        RoomPlayer player = roomPlayerRepo.findByRoomIdAndUserId(roomId, playerId)
                .orElseThrow(() -> new RuntimeException("Player not found in room"));
        if (player.getCharacterToGuess() == null) { throw new IllegalStateException("Player didn't select character"); }

        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found"));
        if (room.getStatus() != RoomStatus.WAITING) {throw new IllegalArgumentException("Room is not in waiting process");}

        player.setReady(!player.isReady());
        return roomPlayerRepo.save(player);
    }

    public Room startGame(UUID roomId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found with id: " + roomId));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new RuntimeException("Room is not ready to start the game");
        }

        // Check if all players are ready
        List<RoomPlayer> players = roomPlayerRepo.findByRoomId(roomId);
        boolean allReady = players.stream().allMatch(RoomPlayer::isReady);
        if (!allReady) {
            throw new RuntimeException("Not all players are ready");
        }

        room.setStatus(RoomStatus.IN_PROGRESS);
        room.setStartedAt(LocalDateTime.now());

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new RuntimeException("Game state not found"));

        if (!players.isEmpty()) {
            gameState.setTurnPlayer(players.get(0));
            gameState.setRoundNumber(1);
        }

        gameStateRepo.save(gameState);
        return roomRepo.save(room);
    }

    public Room finishGame(UUID roomId, UUID winnerId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found with id: " + roomId));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new RuntimeException("Game is not in progress");
        }

        room.setStatus(RoomStatus.FINISHED);
        room.setFinishedAt(LocalDateTime.now());

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new RuntimeException("Game state not found"));
        gameState.setWinnerId(winnerId);

        gameStateRepo.save(gameState);
        return roomRepo.save(room);
    }

    public GameState updateGameState(UUID roomId, UUID turnPlayerId, String currentQuestion, String lastAnswer) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found with id: " + roomId));

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new RuntimeException("Game state not found"));

        RoomPlayer turnPlayer = roomPlayerRepo.findByRoomIdAndUserId(roomId, turnPlayerId)
                .orElseThrow(() -> new RuntimeException("Turn player not found in room"));

        gameState.setTurnPlayer(turnPlayer);
        gameState.setCurrentQuestion(currentQuestion);
        gameState.setLastAnswer(lastAnswer);

        if (gameState.getRoundNumber() != null) {
            gameState.setRoundNumber(gameState.getRoundNumber() + 1);
        } else {
            gameState.setRoundNumber(1);
        }

        return gameStateRepo.save(gameState);
    }

    public Room getRoom(UUID id) {
        return roomRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Room not found with id: " + id));
    }
}
