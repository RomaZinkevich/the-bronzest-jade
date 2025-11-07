package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.dtos.ConnectionInfoDto;
import com.bronzejade.game.domain.dtos.GuessCharacterResponse;
import com.bronzejade.game.domain.dtos.GuessCharacterRequest;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.service.GameStateService;
import com.bronzejade.game.service.RoomPlayerService;
import com.bronzejade.game.service.RoomService;
import com.bronzejade.game.service.GuessCharacterService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.handler.annotation.MessageExceptionHandler;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;

import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class RoomWsController {

    private final SimpMessagingTemplate messagingTemplate;
    private final RoomPlayerService roomPlayerService;
    private final RoomService roomService;
    private final GameStateService gameStateService;
    private final GuessCharacterService guessCharacterService;

    @MessageMapping("/join")
    public void handleMessage(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        String message = messageCrafter(" has joined room", connectionInfoDto.getPlayerId());
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/ready")
    public void toggleReady(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        RoomPlayer roomPlayer = roomService.togglePlayerReady(UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        String message = messageCrafter(" is " + (!roomPlayer.isReady() ? "not " : "") + "ready", connectionInfoDto.getPlayerId());
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/start")
    public void start(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        roomService.startGame(UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        String message = "The game has been started";
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/question")
    public void question(String payload, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        gameStateService.submitQuestion(payload, UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), payload);
    }

    @MessageMapping("/answer")
    public void answer(String payload, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        gameStateService.submitAnswer(payload, UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), payload);
    }

    @MessageMapping("/guess")
    public void guessCharacter(String characterId, SimpMessageHeaderAccessor accessor) {
        System.out.println("=== GUESS WebSocket Called ===");
        System.out.println("Raw characterId: " + characterId);

        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        System.out.println("Room: " + connectionInfoDto.getRoomId());
        System.out.println("Player: " + connectionInfoDto.getPlayerId());

        try {
            System.out.println("Calling guessCharacterService...");
            GuessCharacterResponse response = guessCharacterService.guessCharacter(
                    UUID.fromString(connectionInfoDto.getRoomId()),
                    UUID.fromString(connectionInfoDto.getPlayerId()),
                    UUID.fromString(characterId)
            );
            System.out.println("Response: " + response);
            messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), response);
            System.out.println("Response sent to WebSocket");

        } catch (RuntimeException e) {
            System.out.println("ERROR in guess: " + e.getMessage());
            messagingTemplate.convertAndSendToUser(accessor.getSessionId(), "/queue/errors", e.getMessage());
        }
    }

    @MessageExceptionHandler
    @SendToUser("/queue/errors")
    public String handleException(Exception ex) {
        System.out.println("Error: " + ex.getMessage());
        return ex.getMessage();
    }

    private ConnectionInfoDto retrieveConnectionInfo(SimpMessageHeaderAccessor accessor) {
        String roomId =  (String) accessor.getSessionAttributes().get("roomId");
        String playerId =  (String) accessor.getSessionAttributes().get("playerId");
        if (roomId == null || playerId == null) throw new MessagingException("Room or Player ID is null");
        if (!roomPlayerService.isInRoom(UUID.fromString(roomId), UUID.fromString(playerId))) throw new MessagingException("Player is not in the room");
        ConnectionInfoDto connectionInfoDto = new ConnectionInfoDto();
        connectionInfoDto.setRoomId(roomId);
        connectionInfoDto.setPlayerId(playerId);
        return connectionInfoDto;
    }

    private String messageCrafter(String text, String playerId) {
        StringBuilder sb = new StringBuilder();
        sb.append("guest-player-");
        sb.append(playerId, 0, 6);
        sb.append(text);
        return sb.toString();
    }
}
