package com.bronzejade.game.mapper;

import com.bronzejade.game.domain.dtos.CharacterSetDto;
import com.bronzejade.game.domain.entities.CharacterSet;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface CharacterSetMapper {
    CharacterSetDto toDto(CharacterSet characterSet);
}
