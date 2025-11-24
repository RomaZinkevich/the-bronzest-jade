package com.bronzejade.game.domain.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomPlayerDto {
    private UUID id;
    private String displayName;
    private UUID userId;
    private UUID guestSessionId;

    @JsonProperty("isHost")
    private boolean host;

    @JsonProperty("isReady")
    private boolean ready;

    @JsonProperty("isGuest")
    private boolean guest;

    private CharacterDto characterToGuess;
    private LocalDateTime joinedAt;
}