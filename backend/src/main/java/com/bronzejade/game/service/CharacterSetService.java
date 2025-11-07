package com.bronzejade.game.service;

import com.bronzejade.game.domain.entities.CharacterSet;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.bronzejade.game.repositories.CharacterSetRepository;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CharacterSetService {

    private final CharacterSetRepository characterSetRepository;

    public Set<CharacterSet> getCharacterSets() {
        return characterSetRepository.findByIsPublic(true);
    }

    public CharacterSet getCharacterSet(UUID id) {
        return characterSetRepository.findById(id).orElseThrow(EntityNotFoundException::new);
    }
}
