package com.bronzejade.game.domain.dtos;

import lombok.*;
import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SelectCharacterRequest {
    private UUID userId;              // For authenticated users (nullable)
    private UUID guestSessionId;      // For guest users
    private UUID characterId;
}