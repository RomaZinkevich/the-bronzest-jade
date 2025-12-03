package com.bronzejade.game.service;

import com.bronzejade.game.domain.dtos.Room.CreateRoomRequest;
import com.bronzejade.game.domain.dtos.User.RoomPlayerDto;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.Character;
import com.bronzejade.game.domain.entities.GameState;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.repositories.GameStateRepository;
import com.bronzejade.game.repositories.RoomPlayerRepository;
import com.bronzejade.game.repositories.RoomRepository;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.TurnPhase;
import com.bronzejade.game.repositories.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import com.bronzejade.game.mapper.RoomPlayerMapper;

@Service
@RequiredArgsConstructor
public class RoomService {
    private final RoomRepository roomRepo;
    private final RoomPlayerRepository roomPlayerRepo;
    private final UserRepository userRepo;
    private final GameStateRepository gameStateRepo;
    private final CharacterSetService characterSetService;
    private final RoomPlayerMapper roomPlayerMapper;

    @Transactional
    public Room createRoom(CreateRoomRequest createRoomRequest, UUID userId) {
        CharacterSet characterSet = characterSetService.getCharacterSet(createRoomRequest.getCharacterSetId());

        Room room = Room.builder()
                .characterSet(characterSet)
                .maxPlayers(2)
                .status(RoomStatus.WAITING)
                .build();

        // Always expect a userId (either real user or guest user)
        User hostUser = userRepo.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        room.setHost(hostUser);
        Room savedRoom = roomRepo.save(room);

        // Create host player
        RoomPlayer hostPlayer = RoomPlayer.builder()
                .room(savedRoom)
                .user(hostUser)
                .host(true)
                .ready(false)
                .joinedAt(LocalDateTime.now())
                .build();

        roomPlayerRepo.save(hostPlayer);

        GameState gameState = GameState.builder()
                .room(savedRoom)
                .roundNumber(0)
                .turnPhase(TurnPhase.ASKING)
                .build();

        gameStateRepo.save(gameState);

        return savedRoom;
    }

    public void deleteRoom(UUID id) {
        if (!roomRepo.existsById(id)) {
            throw new EntityNotFoundException("Room not found with id: " + id);
        }
        roomRepo.deleteById(id);
    }

    @Transactional
    public Room joinRoom(String roomCode, UUID userId) { // Only need userId
        Room room = roomRepo.findByRoomCode(roomCode.toUpperCase())
                .orElseThrow(() -> new EntityNotFoundException("Room could not be found"));

        if (room.getStatus() != RoomStatus.WAITING) {
            throw new IllegalArgumentException("Room is not available for joining");
        }

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        // Check if player already in room
        if (roomPlayerRepo.existsByRoomIdAndUser(room.getId(), user)) {
            throw new IllegalArgumentException("Player is already in the room");
        }

        // Check if room is full
        long currentPlayerCount = roomPlayerRepo.countByRoomId(room.getId());
        if (currentPlayerCount >= room.getMaxPlayers()) {
            throw new IllegalArgumentException("Room is full");
        }

        // Create new player
        RoomPlayer player = RoomPlayer.builder()
                .room(room)
                .user(user)
                .host(false)
                .ready(false)
                .joinedAt(LocalDateTime.now())
                .build();

        roomPlayerRepo.save(player);
        return room;
    }

    @Transactional
    public Room leaveRoom(UUID roomId, UUID userId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));
        RoomPlayer player = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));

        boolean wasHost = player.isHost();

        roomPlayerRepo.delete(player);

        if (wasHost) {
            List<RoomPlayer> remainingPlayers = roomPlayerRepo.findByRoomId(roomId);
            if (remainingPlayers.isEmpty()) {
                roomRepo.delete(room);
                return null;
            } else {
                RoomPlayer newHost = remainingPlayers.get(0);
                newHost.setHost(true);
                roomPlayerRepo.save(newHost);

                // Update room's host
                room.setHost(newHost.getUser());
            }
        }

        // Update room status
        long remainingPlayerCount = roomPlayerRepo.countByRoomId(roomId);
        if (remainingPlayerCount < room.getMaxPlayers()) {
            room.setStatus(RoomStatus.WAITING);
        }

        return roomRepo.save(room);
    }

    @Transactional
    public RoomPlayer togglePlayerReady(UUID roomId, UUID userId) {
        // Get user from database
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        // Find player by room and user
        RoomPlayer player = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));

        if (player.getCharacterToGuess() == null) {
            throw new IllegalStateException("Player didn't select character");
        }

        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found"));

        if (room.getStatus() != RoomStatus.WAITING) {
            throw new IllegalArgumentException("Room is not in waiting process");
        }

        player.setReady(!player.isReady());
        return roomPlayerRepo.save(player);
    }

    @Transactional
    public RoomPlayerDto startGame(UUID roomId, UUID userId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        // Check if all players are ready
        List<RoomPlayer> players = roomPlayerRepo.findByRoomId(roomId);
        boolean allReady = players.stream().allMatch(RoomPlayer::isReady);
        if (!allReady) {
            throw new IllegalArgumentException("Not all players are ready");
        }

        // Only host can start the game
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        RoomPlayer requestingPlayer = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));

        if (!requestingPlayer.isHost()) {
            throw new IllegalArgumentException("Player is not host");
        }

        room.setStatus(RoomStatus.IN_PROGRESS);
        room.setStartedAt(LocalDateTime.now());

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Game state not found"));

        // For game to start it should have more than 1 player in it
        if (players.size() > 1) {
            RoomPlayer turnPlayer = players.get((int) (Math.random() * players.size()));
            gameState.setTurnPlayer(turnPlayer);
            gameState.setRoundNumber(1);
            gameStateRepo.save(gameState);
            return roomPlayerMapper.toDto(turnPlayer);
        }
        throw new IllegalArgumentException("Not enough players in the room");
    }

    @Transactional
    public RoomPlayer selectCharacter(UUID roomId, UUID userId, UUID characterId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        if (room.getStatus() != RoomStatus.WAITING) {
            throw new IllegalArgumentException("Cannot select characters when the game is in progress");
        }

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));
        RoomPlayer player = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));

        CharacterSet characterSet = room.getCharacterSet();
        Character character = characterSet.getCharacters().stream()
                .filter(c -> c.getId().equals(characterId))
                .findFirst()
                .orElseThrow(() -> new EntityNotFoundException("Character not found in room's character set"));

        player.setCharacterToGuess(character);
        return roomPlayerRepo.save(player);
    }

    @Transactional
    public Room finishGame(UUID roomId, UUID winnerId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new IllegalArgumentException("Game is not in progress");
        }

        room.setStatus(RoomStatus.FINISHED);
        room.setFinishedAt(LocalDateTime.now());

        GameState gameState = gameStateRepo.findByRoomId(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Game state not found"));
        gameState.setWinnerId(winnerId);

        gameStateRepo.save(gameState);
        return roomRepo.save(room);
    }

    public Room getRoom(UUID id) {
        return roomRepo.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + id));
    }
}
