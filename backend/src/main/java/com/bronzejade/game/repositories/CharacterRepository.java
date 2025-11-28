package com.bronzejade.game.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import com.bronzejade.game.domain.entities.Character;

import java.util.UUID;

public interface CharacterRepository extends JpaRepository<Character, UUID> {
    Character findByName(String name);
}
