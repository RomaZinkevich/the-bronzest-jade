package com.bronzejade.game.domain.dtos;

import lombok.Data;

@Data
public class LoginRequest {
    private String username;
    private String password;
}