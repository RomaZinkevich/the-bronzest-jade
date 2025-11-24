package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.dtos.*;
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
    public void handleJoin(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        MessageDto message = messageCrafter(
                " has joined room",
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId(),
                connectionInfoDto.getDisplayName()
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/ready")
    public void toggleReady(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        RoomPlayer roomPlayer = roomService.togglePlayerReady(
                UUID.fromString(connectionInfoDto.getRoomId()),
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId()
        );
        MessageDto message = messageCrafter(
                " is " + (!roomPlayer.isReady() ? "not " : "") + "ready",
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId(),
                connectionInfoDto.getDisplayName()
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/start")
    public void start(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        RoomPlayerDto roomPlayerDto = roomService.startGame(
                UUID.fromString(connectionInfoDto.getRoomId()),
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId()
        );
        String message = "The game has been started";
        StartGameResponse startGameResponse = new StartGameResponse();
        startGameResponse.setMessage(message);
        startGameResponse.setTurnPlayer(roomPlayerDto);
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), startGameResponse);
    }

    @MessageMapping("/question")
    public void question(String payload, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        gameStateService.submitQuestion(
                payload,
                UUID.fromString(connectionInfoDto.getRoomId()),
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId()
        );
        MessageDto msg = messageCrafter(
                payload,
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId(),
                connectionInfoDto.getDisplayName()
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), msg);
    }

    @MessageMapping("/answer")
    public void answer(String payload, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        gameStateService.submitAnswer(
                payload,
                UUID.fromString(connectionInfoDto.getRoomId()),
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId()
        );
        MessageDto msg = messageCrafter(
                payload,
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId(),
                connectionInfoDto.getDisplayName()
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), msg);
    }

    @MessageMapping("/guess")
    public void guessCharacter(String characterId, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        GuessCharacterResponse response = guessCharacterService.guessCharacter(
                UUID.fromString(connectionInfoDto.getRoomId()),
                connectionInfoDto.getUserId(),
                connectionInfoDto.getGuestSessionId(),
                UUID.fromString(characterId)
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), response);
    }

    @MessageExceptionHandler
    @SendToUser("/queue/errors")
    public String handleException(Exception ex) {
        return ex.getMessage();
    }

    // Retrieves roomId, userId/guestSessionId, and displayName from session
    // and checks if player is in the room
    private ConnectionInfoDto retrieveConnectionInfo(SimpMessageHeaderAccessor accessor) {
        if (accessor.getSessionAttributes() == null) {
            throw new IllegalArgumentException("Session attributes cannot be null");
        }

        String roomId = (String) accessor.getSessionAttributes().get("roomId");
        String userIdStr = (String) accessor.getSessionAttributes().get("userId");
        String guestSessionIdStr = (String) accessor.getSessionAttributes().get("guestSessionId");
        String displayName = (String) accessor.getSessionAttributes().get("displayName");

        if (roomId == null) {
            throw new MessagingException("Room ID is null");
        }

        UUID roomUuid = UUID.fromString(roomId);
        UUID userId = userIdStr != null ? UUID.fromString(userIdStr) : null;
        UUID guestSessionId = guestSessionIdStr != null ? UUID.fromString(guestSessionIdStr) : null;

        if (userId == null && guestSessionId == null) {
            throw new MessagingException("Both User ID and Guest Session ID are null");
        }

        // Check if player is in room
        if (!roomPlayerService.isInRoom(roomUuid, userId, guestSessionId)) {
            throw new MessagingException("Player is not in the room");
        }

        ConnectionInfoDto connectionInfoDto = new ConnectionInfoDto();
        connectionInfoDto.setRoomId(roomId);
        connectionInfoDto.setUserId(userId);
        connectionInfoDto.setGuestSessionId(guestSessionId);
        connectionInfoDto.setDisplayName(displayName);
        return connectionInfoDto;
    }

    private MessageDto messageCrafter(String text, UUID userId, UUID guestSessionId, String displayName) {
        String playerIdentifier;
        if (displayName != null && !displayName.isEmpty()) {
            playerIdentifier = displayName;
        } else if (userId != null) {
            playerIdentifier = "user-" + userId.toString().substring(0, 6);
        } else {
            playerIdentifier = "guest-" + guestSessionId.toString().substring(0, 6);
        }

        String message = playerIdentifier + text;
        return MessageDto.builder()
                .message(message)
                .build();
    }
}