package com.bronzejade.game.service;

import com.bronzejade.game.domain.dtos.CreateCharacterRequest;
import com.bronzejade.game.domain.dtos.CreateCharacterSetRequest;
import com.bronzejade.game.domain.entities.CharacterSet;
import com.bronzejade.game.domain.entities.Character;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.bronzejade.game.repositories.CharacterSetRepository;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CharacterSetService {

    private final CharacterSetRepository characterSetRepository;

    public Set<CharacterSet> getCharacterSets() {
        return characterSetRepository.findByIsPublic(true);
    }

    public CharacterSet getCharacterSet(UUID id) {
        return characterSetRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("CharacterSet with id " + id + " not found"));

    }

    public CharacterSet createSet(CreateCharacterSetRequest createSetRequest) {
        List<CreateCharacterRequest> characterRequests = createSetRequest.getCharacters();
        Set<Character> characters = characterRequests.stream().map((CreateCharacterRequest request) -> {
            Character newCharacter = new Character();
            newCharacter.setName(request.getName());
            newCharacter.setImageUrl(request.getImageUrl());
            return newCharacter;
        }).collect(Collectors.toSet());

        CharacterSet characterSet = new CharacterSet();
        characterSet.setCharacters(characters);
        characterSet.setName(createSetRequest.getName());
        characterSet.setCreatedBy(createSetRequest.getCreatedBy());
        characterSet.setIsPublic(createSetRequest.getIsPublic());

        return characterSetRepository.save(characterSet);
    }
}
