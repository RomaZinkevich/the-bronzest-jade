package com.bronzejade.game.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.util.UUID;

@Entity
@Table(name = "game_action")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class GameAction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "game_state_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private GameState gameState;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asking_player_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private RoomPlayer askingPlayer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "answering_player_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private RoomPlayer answeringPlayer;

    @Column(nullable = false)
    private String question;

    private String answer;

    private Integer roundNumber;
}
