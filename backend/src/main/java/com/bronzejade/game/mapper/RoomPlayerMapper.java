package com.bronzejade.game.mapper;

import com.bronzejade.game.domain.dtos.User.RoomPlayerDto;
import com.bronzejade.game.domain.entities.RoomPlayer;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface RoomPlayerMapper {
    RoomPlayerDto toDto(RoomPlayer roomPlayer);
}