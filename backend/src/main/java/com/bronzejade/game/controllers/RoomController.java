package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.dtos.CreateRoomRequest;
import com.bronzejade.game.domain.dtos.SelectCharacterRequest;
import com.bronzejade.game.domain.dtos.JoinRoomRequest;
import com.bronzejade.game.domain.dtos.LeaveRoomRequest;
import com.bronzejade.game.domain.dtos.FinishGameRequest;
import com.bronzejade.game.domain.dtos.RoomDto;
import com.bronzejade.game.domain.dtos.RoomPlayerDto;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.mapper.RoomMapper;
import com.bronzejade.game.mapper.RoomPlayerMapper;
import com.bronzejade.game.service.RoomService;
import com.bronzejade.game.service.GuessCharacterService;
import com.bronzejade.game.domain.entities.Room;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {
    private final RoomService roomService;
    private final RoomMapper roomMapper;
    private final RoomPlayerMapper roomPlayerMapper;

    @PostMapping
    public ResponseEntity<RoomDto> createRoom(@RequestBody CreateRoomRequest createRoomRequest) {
        Room room = roomService.createRoom(createRoomRequest);
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteRoom(@PathVariable UUID id) {
        roomService.deleteRoom(id);
        return ResponseEntity.ok("Room with id " + id + " has been deleted successfully");
    }

    @PostMapping("/join/{roomCode}")
    public ResponseEntity<RoomDto> joinRoom(@PathVariable String roomCode, @RequestBody JoinRoomRequest joinRequest) {
        UUID playerId = joinRequest.getPlayerId();
        Room room = roomService.joinRoom(roomCode, playerId);
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }

    @PostMapping("/{id}/select-character")
    public ResponseEntity<RoomPlayerDto> selectCharacter(@PathVariable UUID id, @RequestBody SelectCharacterRequest characterRequest) {
        UUID playerId = characterRequest.getPlayerId();
        UUID characterId = characterRequest.getCharacterId();
        RoomPlayer player = roomService.selectCharacter(id, playerId, characterId);
        RoomPlayerDto roomPlayerdto = roomPlayerMapper.toDto(player);
        return ResponseEntity.ok(roomPlayerdto);
    }

    @PostMapping("/{id}/leave")
    public ResponseEntity<Room> leaveRoom(@PathVariable UUID id, @RequestBody LeaveRoomRequest leaveRequest) {
        UUID playerId = leaveRequest.getPlayerId();
        Room room = roomService.leaveRoom(id, playerId);
        if (room == null) {
            return ResponseEntity.ok().body(null); // Room was deleted
        }
        return ResponseEntity.ok(room);
    }

    @PostMapping("/{id}/finish")
    public ResponseEntity<Room> finishGame(@PathVariable UUID id, @RequestBody FinishGameRequest finishGameRequest) {
        UUID winnerId = finishGameRequest.getWinnerId();
        Room room = roomService.finishGame(id, winnerId);
        return ResponseEntity.ok(room);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Room> getRoom(@PathVariable UUID id) {
        Room room = roomService.getRoom(id);
        return ResponseEntity.ok(room);
    }
}
