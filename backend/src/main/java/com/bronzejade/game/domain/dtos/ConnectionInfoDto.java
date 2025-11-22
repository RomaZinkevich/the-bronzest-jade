package com.bronzejade.game.domain.dtos;

import lombok.*;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ConnectionInfoDto {
    private String roomId;
    private String playerId;
}
