package com.bronzejade.game.domain.dtos;

import lombok.*;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StartGameResponse {
    private String message;
    private RoomPlayerDto turnPlayer;
}
