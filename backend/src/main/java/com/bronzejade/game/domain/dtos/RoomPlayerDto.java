package com.bronzejade.game.domain.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class RoomPlayerDto {
    private UUID id;
    private UUID userId;

    @JsonProperty("isHost")
    private boolean host;

    @JsonProperty("isReady")
    private boolean ready;

    private CharacterDto characterToGuess;
    private LocalDateTime joinedAt;
}