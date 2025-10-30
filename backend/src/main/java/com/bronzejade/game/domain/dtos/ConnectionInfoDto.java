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
    private String playerId;
}
