package com.bronzejade.game.domain.dtos.Room;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.dtos.Character.CharacterSetDto;
import com.bronzejade.game.domain.dtos.User.UserDto;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RoomDto {
    private UUID id;
    private String roomCode;
    private UserDto host;
    private RoomStatus status;
    private int maxPlayers;
    private CharacterSetDto characterSet;
    private LocalDateTime createdAt;
    private LocalDateTime startedAt;
    private LocalDateTime finishedAt;
}
