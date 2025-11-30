package com.bronzejade.game.controllers;

import com.bronzejade.game.authFilter.ApiUserDetails;
import com.bronzejade.game.domain.dtos.*;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.mapper.RoomMapper;
import com.bronzejade.game.mapper.RoomPlayerMapper;
import com.bronzejade.game.service.AuthService;
import com.bronzejade.game.service.RoomService;
import com.bronzejade.game.domain.entities.Room;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {
    private final RoomService roomService;
    private final RoomMapper roomMapper;
    private final RoomPlayerMapper roomPlayerMapper;
    private final AuthService userService;

    @PostMapping
    public ResponseEntity<RoomDto> createRoom(
            @Valid @RequestBody CreateRoomRequest createRoomRequest,
            Authentication authentication) {
        UserDto userDto = userService.getUserFromPrincipal((ApiUserDetails) authentication.getPrincipal());
        Room room = roomService.createRoom(createRoomRequest, userDto.getId());
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }

    @PostMapping("/join/{roomCode}")
    public ResponseEntity<RoomDto> joinRoom(
            @PathVariable String roomCode,
            Authentication authentication
    ) {
        UserDto userDto = userService.getUserFromPrincipal((ApiUserDetails) authentication.getPrincipal());
        Room room = roomService.joinRoom(
                roomCode,
                userDto.getId()
        );
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }

    @PostMapping("/{id}/select-character")
    public ResponseEntity<RoomPlayerDto> selectCharacter(
            @PathVariable UUID id,
            @Valid @RequestBody SelectCharacterRequest characterRequest,
            Authentication authentication
    ) {
        UserDto userDto = userService.getUserFromPrincipal((ApiUserDetails) authentication.getPrincipal());
        RoomPlayer player = roomService.selectCharacter(
                id,
                userDto.getId(),
                characterRequest.getCharacterId()
        );
        RoomPlayerDto roomPlayerDto = roomPlayerMapper.toDto(player);
        return ResponseEntity.ok(roomPlayerDto);
    }

    @PostMapping("/{id}/leave")
    public ResponseEntity<RoomDto> leaveRoom(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        UserDto userDto = userService.getUserFromPrincipal((ApiUserDetails) authentication.getPrincipal());
        Room room = roomService.leaveRoom(
                id,
                userDto.getId()
        );
        if (room == null) {
            // Room was deleted
            return ResponseEntity.ok().body(null);
        }
        RoomDto roomDto = roomMapper.toDto(room);
        return ResponseEntity.ok(roomDto);
    }
}
