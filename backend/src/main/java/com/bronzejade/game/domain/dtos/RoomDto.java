package com.bronzejade.game.domain.dtos;

import com.bronzejade.game.domain.RoomStatus;
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
    private UUID hostId;
    private RoomStatus status;
    private int maxPlayers;
    private CharacterSetDto characterSet;
    private LocalDateTime createdAt;
    private LocalDateTime startedAt;
    private LocalDateTime finishedAt;
}
