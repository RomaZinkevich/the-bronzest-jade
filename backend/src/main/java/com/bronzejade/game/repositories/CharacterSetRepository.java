package com.bronzejade.game.repositories;

import com.bronzejade.game.domain.entities.CharacterSet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Set;
import java.util.UUID;

public interface CharacterSetRepository extends JpaRepository<CharacterSet, UUID> {
    Set<CharacterSet> findByIsPublic(Boolean isPublic);
}
