package com.bronzejade.game.domain.dtos;

import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SelectCharacterRequest {
    @NotNull(message = "User ID is required")
    private UUID userId;

    @NotNull(message = "Character ID is required")
    private UUID characterId;
}