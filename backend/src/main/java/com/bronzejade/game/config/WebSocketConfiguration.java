package com.bronzejade.game.config;

import com.bronzejade.game.service.RoomPlayerService;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
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

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfiguration implements WebSocketMessageBrokerConfigurer {

    private final RoomPlayerService roomPlayerService;

    public WebSocketConfiguration(RoomPlayerService roomPlayerService) {
        this.roomPlayerService = roomPlayerService;
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Enable a simple memory-based message broker for destinations prefixed with /topic or /queue
        config.enableSimpleBroker("/topic");

        // Set prefix for messages from client to server
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Register WebSocket endpoint that clients will use to connect
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")  // Configure CORS as needed
                .withSockJS();  // Enable SockJS fallback options
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor =
                        MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

                if (StompCommand.CONNECT.equals(accessor.getCommand())) {
                    // Try to extract playerId from native headers
                    String playerId = accessor.getFirstNativeHeader("playerId");
                    String roomId = accessor.getFirstNativeHeader("roomId");

                    if (playerId != null && roomId != null) {
                        accessor.getSessionAttributes().put("playerId", playerId);
                        accessor.getSessionAttributes().put("roomId", roomId);
                    }
                }

                if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
                    String destination = accessor.getDestination();
                    if (destination.contains("room")) {
                        UUID playerId = UUID.fromString((String) accessor.getSessionAttributes().get("playerId"));
                        UUID roomId = UUID.fromString((String) accessor.getSessionAttributes().get("roomId"));

                        if (!roomPlayerService.isInRoom(roomId, playerId)) {
                            throw new IllegalArgumentException("Access to this room is forbidden.");
                        }
                    }
                }

                return message;
            }
        });
    }
}
