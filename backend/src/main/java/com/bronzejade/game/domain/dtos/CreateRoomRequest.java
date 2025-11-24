package com.bronzejade.game.domain.dtos;

import lombok.*;

import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Data
public class CreateRoomRequest {
    private UUID characterSetId;
    private UUID userId; // For authenticated users
    private UUID guestSessionId; // For guest users
    private String guestDisplayName; // For guest users
}
