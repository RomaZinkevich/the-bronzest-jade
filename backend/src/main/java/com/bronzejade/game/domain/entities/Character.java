package com.bronzejade.game.domain.entities;

import jakarta.persistence.*;
import lombok.*;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "characters")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class Character {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String image_url;

    @ManyToMany(mappedBy = "characters", fetch = FetchType.LAZY)
    private Set<CharacterSet> characterSets = new HashSet<>();
}
