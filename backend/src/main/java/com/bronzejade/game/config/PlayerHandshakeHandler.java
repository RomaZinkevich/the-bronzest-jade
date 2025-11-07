package com.bronzejade.game.config;

import org.springframework.http.server.ServerHttpRequest;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;

import java.security.Principal;
import java.util.Map;
import java.util.UUID;

public class PlayerHandshakeHandler extends DefaultHandshakeHandler {
    @Override
    protected Principal determineUser(ServerHttpRequest request,
                                      WebSocketHandler wsHandler,
                                      Map<String, Object> attributes) {

        String playerId = (String) attributes.get("playerId");

        if (playerId == null || playerId.isBlank()) {
            playerId = "anon-" + UUID.randomUUID();
        }

        final String finalPlayerId = playerId;
        return () -> finalPlayerId;
    }
}
