package com.bronzejade.game.domain.dtos;

import lombok.*;

import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ToggleReadyRequest {
    private UUID playerId;
}
