package com.bronzejade.game.config;

import com.bronzejade.game.security.JwtUtil;
import com.bronzejade.game.service.AuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;
import java.util.UUID;

/**
 * Intercepts the WebSocket handshake to extract the "userId" from the request
 * and store it in WebSocket session attributes for later use (e.g., in HandshakeHandler).
 */
@Component
@Slf4j
public class PlayerHandshakeInterceptor implements HandshakeInterceptor {
    private final AuthService authService;
    private final JwtUtil jwtUtil;

    public PlayerHandshakeInterceptor(AuthService authService, JwtUtil jwtUtil) {
        this.authService = authService;
        this.jwtUtil = jwtUtil;
    }

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {

        String query = request.getURI().getQuery();
        if (query == null || !query.contains("token=")) {
            response.setStatusCode(HttpStatus.FORBIDDEN);
            return false;
        }

        String token = query.substring(query.indexOf("token=") + 6);
        if (!authService.validateToken(token)) {
            response.setStatusCode(HttpStatus.FORBIDDEN);
            return false;
        }

        String roomId = request.getHeaders().getFirst("roomId");
        UUID userId = jwtUtil.validateTokenAndGetUserId(token);
        String stringUserId = String.valueOf(userId);

        if (stringUserId != null && !stringUserId.isBlank()) {
            attributes.put("userId", stringUserId);
        }

        if (roomId != null && !roomId.isBlank()) {
            attributes.put("roomId", roomId);
        }

        String displayName = authService.getUsername(userId);

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
