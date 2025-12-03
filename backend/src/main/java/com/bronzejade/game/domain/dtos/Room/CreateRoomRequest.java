package com.bronzejade.game.domain.dtos.Room;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Data
public class CreateRoomRequest {
    @NotNull(message = "CharacterSet ID is required")
    private UUID characterSetId;
}
