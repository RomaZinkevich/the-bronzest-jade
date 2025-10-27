package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.entities.GameState;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.service.RoomService;
import com.bronzejade.game.domain.entities.Room;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {
    private final RoomService roomService;

    @PostMapping
    public ResponseEntity<Room> createRoom(@RequestBody Map<String, String> request) {
        try {
            UUID hostId = UUID.fromString(request.get("hostId"));
            Room room = roomService.createRoom(hostId);
            return ResponseEntity.ok(room);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteRoom(@PathVariable UUID id) {
        try {
            roomService.deleteRoom(id);
            return ResponseEntity.ok("Room with id " + id + " has been deleted successfully");
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/join/{roomCode}")
    public ResponseEntity<Room> joinRoom(@PathVariable String roomCode, @RequestBody Map<String, String> request) {
        try {
            UUID playerId = UUID.fromString(request.get("playerId"));
            Room room = roomService.joinRoom(roomCode, playerId);
            return ResponseEntity.ok(room);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(null);
        }
    }

    @PostMapping("/{id}/leave")
    public ResponseEntity<Room> leaveRoom(@PathVariable UUID id, @RequestBody Map<String, String> request) {
        try {
            UUID playerId = UUID.fromString(request.get("playerId"));
            Room room = roomService.leaveRoom(id, playerId);
            if (room == null) {
                return ResponseEntity.ok().body(null); // Room was deleted
            }
            return ResponseEntity.ok(room);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/ready")
    public ResponseEntity<RoomPlayer> toggleReady(@PathVariable UUID id, @RequestBody Map<String, String> request) {
        try {
            UUID playerId = UUID.fromString(request.get("playerId"));
            RoomPlayer player = roomService.togglePlayerReady(id, playerId);
            return ResponseEntity.ok(player);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/start")
    public ResponseEntity<Room> startGame(@PathVariable UUID id) {
        try {
            Room room = roomService.startGame(id);
            return ResponseEntity.ok(room);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/finish")
    public ResponseEntity<Room> finishGame(@PathVariable UUID id, @RequestBody Map<String, String> request) {
        try {
            UUID winnerId = UUID.fromString(request.get("winnerId"));
            Room room = roomService.finishGame(id, winnerId);
            return ResponseEntity.ok(room);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{id}/game-state")
    public ResponseEntity<GameState> updateGameState(@PathVariable UUID id, @RequestBody Map<String, String> request) {
        try {
            UUID turnPlayerId = UUID.fromString(request.get("turnPlayerId"));
            String currentQuestion = request.get("currentQuestion");
            String lastAnswer = request.get("lastAnswer");

            GameState gameState = roomService.updateGameState(id, turnPlayerId, currentQuestion, lastAnswer);
            return ResponseEntity.ok(gameState);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Room> getRoom(@PathVariable UUID id) {
        try {
            Room room = roomService.getRoom(id);
            return ResponseEntity.ok(room);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
