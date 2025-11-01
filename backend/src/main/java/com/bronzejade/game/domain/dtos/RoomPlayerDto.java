package com.bronzejade.game.domain.dtos;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomPlayerDto {
    private UUID id;
    private UUID roomId;
    private UUID userId;
    private boolean isHost;
    private boolean isReady;
    private CharacterDto characterToGuess;
    private LocalDateTime joinedAt;
}