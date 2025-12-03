package com.bronzejade.game.domain.dtos.User;

import lombok.Data;

@Data
public class LoginRequest {
    private String username;
    private String password;
}