package com.bronzejade.game.domain.entities;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "character_sets")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class CharacterSet {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String createdBy;

    @Column(nullable = false)
    private Boolean isPublic;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @ManyToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinTable(
            name = "character_set_characters",
            joinColumns = @JoinColumn(name = "character_set_id"),
            inverseJoinColumns = @JoinColumn(name = "character_id")
    )
    private Set<Character> characters = new HashSet<>();

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();
        if (this.isPublic == null) {
            this.isPublic = true;
        }
        if (this.createdBy == null) {
            this.createdBy = "system";
        }
    }
}
