package com.bronzejade.game.domain.dtos.User;

import com.bronzejade.game.domain.dtos.Character.CharacterDto;
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

    @JsonProperty("isGuest")
    private boolean guest;

    private CharacterDto characterToGuess;
    private LocalDateTime joinedAt;
}