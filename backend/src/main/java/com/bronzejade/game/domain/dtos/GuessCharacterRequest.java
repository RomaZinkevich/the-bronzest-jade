package com.bronzejade.game.domain.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GuessCharacterRequest {
    private UUID roomId;
    private UUID playerId;
    private UUID guessedCharacterId;
}