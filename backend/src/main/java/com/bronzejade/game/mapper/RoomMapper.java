package com.bronzejade.game.mapper;

import com.bronzejade.game.domain.dtos.RoomDto;
import com.bronzejade.game.domain.entities.Room;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface RoomMapper {
    RoomDto toDto(Room room);
}
