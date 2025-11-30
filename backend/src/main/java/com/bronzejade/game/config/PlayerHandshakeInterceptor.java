package com.bronzejade.game.config;

import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

/**
 * Intercepts the WebSocket handshake to extract the "userId" from the request
 * and store it in WebSocket session attributes for later use (e.g., in HandshakeHandler).
 */
@Component
public class PlayerHandshakeInterceptor implements HandshakeInterceptor {
    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {

        String userId = request.getHeaders().getFirst("userId");
        String roomId = request.getHeaders().getFirst("roomId");
        String displayName = request.getHeaders().getFirst("displayName");

        //storing in session attributes
        if (userId != null && !userId.isBlank()) {
            attributes.put("userId", userId);
        }

        if (roomId != null && !roomId.isBlank()) {
            attributes.put("roomId", roomId);
        }

        if (displayName != null && !displayName.isBlank()) {
            attributes.put("displayName", displayName);
        }
        return true;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request,
                               ServerHttpResponse response,
                               WebSocketHandler wsHandler,
                               Exception exception) {
    }
}
