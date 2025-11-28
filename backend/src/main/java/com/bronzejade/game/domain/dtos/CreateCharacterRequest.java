package com.bronzejade.game.domain.dtos;

import lombok.*;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateCharacterRequest {
    private String name;
    private String imageUrl;
}
