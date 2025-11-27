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
import com.bronzejade.game.domain.entities.Room;
import jakarta.validation.Valid;
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
    public ResponseEntity<RoomDto> createRoom(@Valid @RequestBody CreateRoomRequest createRoomRequest) {
        Room room = roomService.createRoom(createRoomRequest);
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }

    @PostMapping("/join/{roomCode}")
    public ResponseEntity<RoomDto> joinRoom(@PathVariable String roomCode, @Valid @RequestBody JoinRoomRequest joinRequest) {
        Room room = roomService.joinRoom(
                roomCode,
                joinRequest.getUserId()
        );
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }

    @PostMapping("/{id}/select-character")
    public ResponseEntity<RoomPlayerDto> selectCharacter(@PathVariable UUID id, @Valid @RequestBody SelectCharacterRequest characterRequest) {
        RoomPlayer player = roomService.selectCharacter(
                id,
                characterRequest.getUserId(),
                characterRequest.getCharacterId()
        );
        RoomPlayerDto roomPlayerDto = roomPlayerMapper.toDto(player);
        return ResponseEntity.ok(roomPlayerDto);
    }

    @PostMapping("/{id}/leave")
    public ResponseEntity<RoomDto> leaveRoom(@PathVariable UUID id, @Valid @RequestBody LeaveRoomRequest leaveRequest) {
        Room room = roomService.leaveRoom(
                id,
                leaveRequest.getUserId()
        );
        if (room == null) {
            // Room was deleted
            return ResponseEntity.ok().body(null);
        }
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }
}
