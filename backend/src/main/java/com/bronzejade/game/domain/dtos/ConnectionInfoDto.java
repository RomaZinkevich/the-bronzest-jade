package com.bronzejade.game.domain.dtos;

import lombok.*;

import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ConnectionInfoDto {
    private String roomId;
    private UUID userId; // For authenticated users
    private UUID guestSessionId; // For guest users
    private String displayName; // Optional display name from session
}
