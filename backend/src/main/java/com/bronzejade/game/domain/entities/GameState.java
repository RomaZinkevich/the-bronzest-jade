package com.bronzejade.game.domain.entities;

import com.bronzejade.game.domain.TurnPhase;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.util.UUID;

@Entity
@Table(name = "game_state")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class GameState {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "turn_player_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private RoomPlayer turnPlayer;

    @Enumerated(EnumType.STRING)
    private TurnPhase turnPhase;

    private Integer roundNumber;

    private UUID winnerId;
}
