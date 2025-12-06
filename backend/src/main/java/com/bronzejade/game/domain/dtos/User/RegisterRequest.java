package com.bronzejade.game.domain.dtos.User;

import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class RegisterRequest{
    private String username;
    private String email;

    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$",
            message = "Password must be at least 8 characters long, contain upper & lowercase letters, a number, and a special character (@$!%*?&)"
    )
    private String password;
}