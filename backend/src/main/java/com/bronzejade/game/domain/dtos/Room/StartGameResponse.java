package com.bronzejade.game.domain.dtos.Room;

import com.bronzejade.game.domain.dtos.User.RoomPlayerDto;
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
