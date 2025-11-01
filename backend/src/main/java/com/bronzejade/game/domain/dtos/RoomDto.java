package com.bronzejade.game.domain.dtos;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.entities.CharacterSet;
import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;
import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RoomDto {
    private UUID id;
    private String roomCode;
    private UUID hostId;
    private RoomStatus status;
    private int maxPlayers;
    private CharacterSetDto characterSet;
    private LocalDateTime createdAt;
    private LocalDateTime startedAt;
    private LocalDateTime finishedAt;
}
