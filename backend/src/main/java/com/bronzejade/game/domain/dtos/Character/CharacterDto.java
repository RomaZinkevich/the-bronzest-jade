package com.bronzejade.game.domain.dtos.Character;

import lombok.*;

import java.util.UUID;

@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class CharacterDto {
    private UUID id;
    private String name;
    private String imageUrl;
}
