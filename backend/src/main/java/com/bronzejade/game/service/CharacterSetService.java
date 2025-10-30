package com.bronzejade.game.service;

import com.bronzejade.game.domain.entities.CharacterSet;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.bronzejade.game.repositories.CharacterSetRepository;

import java.util.Set;

@Service
@RequiredArgsConstructor
public class CharacterSetService {

    private final CharacterSetRepository characterSetRepository;

    public Set<CharacterSet> getCharacterSets() {
        return characterSetRepository.findByIsPublic(true);
    }
}
