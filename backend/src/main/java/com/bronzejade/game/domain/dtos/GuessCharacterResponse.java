package com.bronzejade.game.domain.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder(toBuilder = true)
public class GuessCharacterResponse {
    private boolean correct;
    private UUID guessedCharacterId;
    private String guessedCharacterName;
    private UUID actualCharacterId;
    private String actualCharacterName;
    private boolean gameEnded;
    private UUID winnerId;
    private String message;
}