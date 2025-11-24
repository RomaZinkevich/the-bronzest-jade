package com.bronzejade.game.service;

import com.bronzejade.game.domain.dtos.CreateRoomRequest;
import com.bronzejade.game.domain.dtos.RoomPlayerDto;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.Character;
import com.bronzejade.game.domain.entities.GameState;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.entities.User;
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
    public Room createRoom(CreateRoomRequest createRoomRequest) {
        CharacterSet characterSet = characterSetService.getCharacterSet(createRoomRequest.getCharacterSetId());

        Room room = Room.builder()
                .characterSet(characterSet)
                .maxPlayers(2)
                .status(RoomStatus.WAITING)
                .build();

        Room savedRoom = roomRepo.save(room);

        // Create host player (can be authenticated or guest)
        RoomPlayer.RoomPlayerBuilder hostBuilder = RoomPlayer.builder()
                .room(savedRoom)
                .host(true)
                .ready(false)
                .joinedAt(LocalDateTime.now());

        if (createRoomRequest.getUserId() != null) {
            // Authenticated user
            User user = userRepo.findById(createRoomRequest.getUserId())
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));
            hostBuilder.user(user);
            room.setHostId(user.getId());
        } else {
            // Guest user
            hostBuilder.guestSessionId(createRoomRequest.getGuestSessionId())
                    .guestDisplayName(createRoomRequest.getGuestDisplayName());
            room.setHostId(createRoomRequest.getGuestSessionId());
        }

        roomPlayerRepo.save(hostBuilder.build());

        GameState gameState = GameState.builder()
                .room(savedRoom)
                .roundNumber(0)
                .turnPhase(TurnPhase.ASKING)
                .build();

        gameStateRepo.save(gameState);

        return roomRepo.save(savedRoom);
    }

    public void deleteRoom(UUID id) {
        if (!roomRepo.existsById(id)) {
            throw new EntityNotFoundException("Room not found with id: " + id);
        }
        roomRepo.deleteById(id);
    }

    @Transactional
    public Room joinRoom(String roomCode, UUID userId, UUID guestSessionId, String guestDisplayName) {
        Room room = roomRepo.findByRoomCode(roomCode.toUpperCase())
                .orElseThrow(() -> new EntityNotFoundException("Room could not be found"));

        UUID roomId = room.getId();

        if (room.getStatus() != RoomStatus.WAITING) {
            throw new IllegalArgumentException("Room is not available for joining");
        }

        // Check if player already in room
        boolean playerAlreadyInRoom;
        if (userId != null) {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));
            playerAlreadyInRoom = roomPlayerRepo.existsByRoomIdAndUser(roomId, user);
        } else {
            playerAlreadyInRoom = roomPlayerRepo.existsByRoomIdAndGuestSessionId(roomId, guestSessionId);
        }

        if (playerAlreadyInRoom) {
            throw new IllegalArgumentException("Player is already in the room");
        }

        // Check if room is full
        long currentPlayerCount = roomPlayerRepo.countByRoomId(roomId);
        if (currentPlayerCount >= room.getMaxPlayers()) {
            throw new IllegalArgumentException("Room is full");
        }

        // Create new player
        RoomPlayer.RoomPlayerBuilder playerBuilder = RoomPlayer.builder()
                .room(room)
                .host(false)
                .ready(false)
                .joinedAt(LocalDateTime.now());

        if (userId != null) {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));
            playerBuilder.user(user);
        } else {
            playerBuilder.guestSessionId(guestSessionId)
                    .guestDisplayName(guestDisplayName);
        }

        roomPlayerRepo.save(playerBuilder.build());

        return room;
    }

    @Transactional
    public Room leaveRoom(UUID roomId, UUID userId, UUID guestSessionId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        RoomPlayer player;
        if (userId != null) {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));
            player = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        } else {
            player = roomPlayerRepo.findByRoomIdAndGuestSessionId(roomId, guestSessionId)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        }

        boolean wasHost = player.isHost();

        roomPlayerRepo.delete(player);

        if (wasHost) {
            List<RoomPlayer> remainingPlayers = roomPlayerRepo.findByRoomId(roomId);
            if (remainingPlayers.isEmpty()) {
                // No players left, delete room
                roomRepo.delete(room);
                return null;
            } else {
                // Assign new host
                RoomPlayer newHost = remainingPlayers.get(0);
                newHost.setHost(true);
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

    @Transactional
    public RoomPlayer togglePlayerReady(UUID roomId, UUID userId, UUID guestSessionId) {
        RoomPlayer player;
        if (userId != null) {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));
            player = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        } else {
            player = roomPlayerRepo.findByRoomIdAndGuestSessionId(roomId, guestSessionId)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        }

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
    public RoomPlayerDto startGame(UUID roomId, UUID userId, UUID guestSessionId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        // Check if all players are ready
        List<RoomPlayer> players = roomPlayerRepo.findByRoomId(roomId);
        boolean allReady = players.stream().allMatch(RoomPlayer::isReady);
        if (!allReady) {
            throw new IllegalArgumentException("Not all players are ready");
        }

        // Only host can start the game
        RoomPlayer requestingPlayer;
        if (userId != null) {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));
            requestingPlayer = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        } else {
            requestingPlayer = roomPlayerRepo.findByRoomIdAndGuestSessionId(roomId, guestSessionId)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        }

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
    public RoomPlayer selectCharacter(UUID roomId, UUID userId, UUID guestSessionId, UUID characterId) {
        Room room = roomRepo.findById(roomId)
                .orElseThrow(() -> new EntityNotFoundException("Room not found with id: " + roomId));

        if (room.getStatus() != RoomStatus.WAITING) {
            throw new IllegalArgumentException("Cannot select characters when the game is in progress");
        }

        RoomPlayer player;
        if (userId != null) {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));
            player = roomPlayerRepo.findByRoomIdAndUser(roomId, user)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        } else {
            player = roomPlayerRepo.findByRoomIdAndGuestSessionId(roomId, guestSessionId)
                    .orElseThrow(() -> new EntityNotFoundException("Player not found in room"));
        }

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
