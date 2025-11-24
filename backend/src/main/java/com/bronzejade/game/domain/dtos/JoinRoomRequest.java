package com.bronzejade.game.domain.dtos;

import lombok.*;
import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class JoinRoomRequest {
    private UUID userId;              // For authenticated users (nullable)
    private String guestDisplayName;  // For guest users
    private UUID guestSessionId;      // For guest users
}