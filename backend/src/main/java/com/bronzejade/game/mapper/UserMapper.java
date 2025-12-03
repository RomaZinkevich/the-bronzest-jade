package com.bronzejade.game.mapper;

import com.bronzejade.game.domain.dtos.User.UserDto;
import com.bronzejade.game.domain.entities.User;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface UserMapper {
    UserDto toDto(User user);
}
