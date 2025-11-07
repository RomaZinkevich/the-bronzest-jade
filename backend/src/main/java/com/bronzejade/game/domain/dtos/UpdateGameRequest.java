package com.bronzejade.game.domain.dtos;

import lombok.*;

import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpdateGameRequest {
    private UUID turnPlayerId;
    private String currentQuestion;
    private String lastAnswer;
}
