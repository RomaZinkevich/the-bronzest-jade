package com.bronzejade.game.domain.dtos.User;

import lombok.*;

import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ConnectionInfoDto {
    private String roomId;
    private UUID userId;
    private String displayName;
}
