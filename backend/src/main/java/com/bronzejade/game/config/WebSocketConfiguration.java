package com.bronzejade.game.config;

import com.bronzejade.game.security.JwtUtil;
import com.bronzejade.game.service.AuthService;
import com.bronzejade.game.service.RoomPlayerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.UUID;

/**
 * Configures STOMP WebSocket messaging, endpoint registration, message broker setup,
 * and inbound message validation for room access.
 */
@Configuration
@EnableWebSocketMessageBroker
@Slf4j
public class WebSocketConfiguration implements WebSocketMessageBrokerConfigurer {

    private final RoomPlayerService roomPlayerService;
    private final PlayerHandshakeInterceptor playerHandshakeInterceptor;
    private final JwtUtil jwtUtil;
    private final AuthService authService;

    public WebSocketConfiguration(RoomPlayerService roomPlayerService, PlayerHandshakeInterceptor playerHandshakeInterceptor, AuthService authService, JwtUtil jwtUtil) {
        this.roomPlayerService = roomPlayerService;
        this.playerHandshakeInterceptor = playerHandshakeInterceptor;
        this.jwtUtil = jwtUtil;
        this.authService = authService;
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Prefix for application-level message mappings (@MessageMapping)
        config.setApplicationDestinationPrefixes("/app");
        // Enable simple in-memory message broker for subscribing to destinations
        config.enableSimpleBroker("/topic", "/queue");
        // Prefix for user-specific destinations (/user/...)
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Register WebSocket endpoint that clients will use to connect
        registry.addEndpoint("/ws")
                .addInterceptors(playerHandshakeInterceptor) // Extracts playerId before handshake
                .setHandshakeHandler(new PlayerHandshakeHandler(authService, jwtUtil)) // Assigns Principal per connection
                .setAllowedOriginPatterns("http://localhost:8080", "http://localhost:63342","http://127.0.0.1:5500", "https://guesswho.190304.xyz", "https://guess-who-web-nine.vercel.app")  // Configure CORS as needed
                .withSockJS();  // Enable SockJS fallback options
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        // Intercepts incoming STOMP frames to validate room membership
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor =
                        MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

                if (StompCommand.CONNECT.equals(accessor.getCommand())) {
                    // Try to extract playerId from native headers
                    String userId = (String) accessor.getSessionAttributes().get("userId");
                    String roomId = accessor.getFirstNativeHeader("roomId");

                    if (userId == null || roomId == null) {
                        throw new MessagingException("Missing userId or roomId in WebSocket session attributes.");
                    }
                    accessor.getSessionAttributes().put("roomId", roomId);
                }

                if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
                    String destination = accessor.getDestination();
                    // Validate that the subscribing player is actually in the room
                    if (destination.contains("room")) {
                        UUID userId = UUID.fromString((String) accessor.getSessionAttributes().get("userId"));
                        UUID roomId = UUID.fromString((String) accessor.getSessionAttributes().get("roomId"));

                        if (!roomPlayerService.isInRoom(roomId, userId)) {
                            throw new MessagingException("Access to this room is forbidden.");
                        }
                    }
                }

                return message;
            }
        });
    }
}
