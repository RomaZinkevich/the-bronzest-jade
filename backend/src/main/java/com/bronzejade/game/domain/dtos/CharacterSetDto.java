package com.bronzejade.game.domain.dtos;

import lombok.*;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CharacterSetDto {
    private UUID id;
    private String name;
    private String createdBy;
    private Boolean isPublic;
    private LocalDateTime createdAt;
    private Set<CharacterDto> characters = new HashSet<>();
}
