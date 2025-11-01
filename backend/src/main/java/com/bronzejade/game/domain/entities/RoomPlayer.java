package com.bronzejade.game.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "room_players")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class RoomPlayer {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Room room;

    @Column(nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private boolean isHost;

    @Column(nullable = false)
    private boolean isReady;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "character_to_guess_id")
    @OnDelete(action = OnDeleteAction.RESTRICT)
    private Character characterToGuess;

    @Column(nullable = false)
    private LocalDateTime joinedAt;

    @PrePersist
    public void onCreate() {
        this.joinedAt = LocalDateTime.now();
        this.isReady = false;
    }
}
