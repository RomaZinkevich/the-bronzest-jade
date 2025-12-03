package com.bronzejade.game.domain.dtos.Room;

import lombok.*;

import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Data
public class ToggleReadyRequest {
    private UUID userId;
}
