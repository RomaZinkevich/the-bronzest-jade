package com.bronzejade.game.config;

import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

/**
 * Intercepts the WebSocket handshake to extract the "playerId" from the request
 * and store it in WebSocket session attributes for later use (e.g., in HandshakeHandler).
 */
@Component
public class PlayerHandshakeInterceptor implements HandshakeInterceptor {
    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {

        // Access underlying servlet request to read URL query parameters
        if (request instanceof ServletServerHttpRequest) {
            var servletRequest = ((ServletServerHttpRequest) request).getServletRequest();
            String playerId = servletRequest.getParameter("playerId");
            if (playerId != null && !playerId.isBlank()) {
                attributes.put("playerId", playerId); //Store for later user
            }
        }
        return true; // Always allow connection
    }

    @Override
    public void afterHandshake(ServerHttpRequest request,
                               ServerHttpResponse response,
                               WebSocketHandler wsHandler,
                               Exception exception) {
        // nothing needed here
    }
}
