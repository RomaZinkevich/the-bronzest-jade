package com.bronzejade.game.domain.dtos.Character;

import lombok.*;
import java.util.List;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateCharacterSetRequest {
    private String name;
    private Boolean isPublic;
    private List<CreateCharacterRequest> characters;
}
