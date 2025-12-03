package com.bronzejade.game.mapper;

import com.bronzejade.game.domain.dtos.User.RoomPlayerDto;
import com.bronzejade.game.domain.entities.RoomPlayer;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface RoomPlayerMapper {

    @Mapping(target = "userId", source = "user.id")
    @Mapping(target = "guest", expression = "java(roomPlayer.isGuest())")
    RoomPlayerDto toDto(RoomPlayer roomPlayer);
}