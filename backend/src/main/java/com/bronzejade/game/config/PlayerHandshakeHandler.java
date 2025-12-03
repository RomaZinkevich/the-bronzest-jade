package com.bronzejade.game.config;

import com.bronzejade.game.security.JwtUtil;
import com.bronzejade.game.service.AuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;

import java.net.URI;
import java.security.Principal;
import java.util.Map;
import java.util.UUID;

/**
 * Custom handshake handler that assigns a unique Principal to each WebSocket connection.
 * Uses provided "playerId" attribute if available; otherwise generates an anonymous ID.
 */
@Component
@Slf4j
public class PlayerHandshakeHandler extends DefaultHandshakeHandler {

    private final AuthService authService;
    private final JwtUtil jwtUtil;

    public PlayerHandshakeHandler(AuthService authService, JwtUtil jwtUtil) {
        this.authService = authService;
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected Principal determineUser(ServerHttpRequest request,
                                      WebSocketHandler wsHandler,
                                      Map<String, Object> attributes) {

        URI uri = request.getURI();
        String query = uri.getQuery();
        String token = null;
        if (query != null && query.contains("token=")) {
            token = query.substring(6);
        }
        if (token == null) {
            throw new IllegalArgumentException("Missing JWT token");
        }

        if (!authService.validateToken(token)) {
            throw new IllegalArgumentException("Invalid JWT token");
        }

        UUID userId = jwtUtil.validateTokenAndGetUserId(token);
        final String finalPlayerId = userId.toString();
        return () -> finalPlayerId;
    }
}
