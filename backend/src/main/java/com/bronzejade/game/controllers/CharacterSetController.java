package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.dtos.CharacterSetDto;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.mapper.CharacterSetMapper;
import com.bronzejade.game.service.CharacterSetService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/character-sets")
@RequiredArgsConstructor
public class CharacterSetController {

    private final CharacterSetService characterSetService;
    private final CharacterSetMapper characterSetMapper;

    @GetMapping()
    public ResponseEntity<Set<CharacterSetDto>> getAllCharacterSets() {
        Set<CharacterSet> characterSets = characterSetService.getCharacterSets();
        Set<CharacterSetDto> characterSetDtos = characterSets.stream().map(characterSetMapper::toDto).collect(Collectors.toSet());
        return ResponseEntity.ok(characterSetDtos);
    }

    @GetMapping(path="/{id}")
    public ResponseEntity<CharacterSetDto> getCharacterSet(@PathVariable UUID id) {
        CharacterSet characterSet = characterSetService.getCharacterSet(id);
        CharacterSetDto dto = characterSetMapper.toDto(characterSet);
        return ResponseEntity.ok(dto);
    }
}
