package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.dtos.*;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.domain.entities.User;
import com.bronzejade.game.repositories.UserRepository;
import com.bronzejade.game.service.GameStateService;
import com.bronzejade.game.service.RoomPlayerService;
import com.bronzejade.game.service.RoomService;
import com.bronzejade.game.service.GuessCharacterService;
import jakarta.persistence.EntityNotFoundException;
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
    private final UserRepository userRepo;
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
                connectionInfoDto.getDisplayName()
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/ready")
    public void toggleReady(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        RoomPlayer roomPlayer = roomService.togglePlayerReady(
                UUID.fromString(connectionInfoDto.getRoomId()),
                connectionInfoDto.getUserId()
        );
        MessageDto message = messageCrafter(
                " is " + (!roomPlayer.isReady() ? "not " : "") + "ready",
                connectionInfoDto.getUserId(),
                connectionInfoDto.getDisplayName()
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/start")
    public void start(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        RoomPlayerDto roomPlayerDto = roomService.startGame(
                UUID.fromString(connectionInfoDto.getRoomId()),
                connectionInfoDto.getUserId()
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
                connectionInfoDto.getUserId()
        );
        MessageDto msg = messageCrafter(
                payload,
                connectionInfoDto.getUserId(),
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
                connectionInfoDto.getUserId()
        );
        MessageDto msg = messageCrafter(
                payload,
                connectionInfoDto.getUserId(),
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
                UUID.fromString(characterId)
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), response);
    }

    @MessageExceptionHandler
    @SendToUser("/queue/errors")
    public String handleException(Exception ex) {
        System.out.println("Error " +  ex.getMessage());
        return ex.getMessage();
    }

    // Checks if the player is in the room
    private ConnectionInfoDto retrieveConnectionInfo(SimpMessageHeaderAccessor accessor) {
        if (accessor.getSessionAttributes() == null) {
            throw new IllegalArgumentException("Session attributes cannot be null");
        }

        String roomId = (String) accessor.getSessionAttributes().get("roomId");
        String userIdStr = (String) accessor.getSessionAttributes().get("userId");

        if (roomId == null) {
            throw new MessagingException("Room ID is null");
        }

        UUID roomUuid = UUID.fromString(roomId);
        UUID userId = userIdStr != null ? UUID.fromString(userIdStr) : null;

        if (userId == null) {
            throw new MessagingException("Both User ID and Guest Session ID are null");
        }

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        // Check if player is in room
        if (!roomPlayerService.isInRoom(roomUuid, userId)) {
            throw new MessagingException("Player is not in the room");
        }

        ConnectionInfoDto connectionInfoDto = new ConnectionInfoDto();
        connectionInfoDto.setRoomId(roomId);
        connectionInfoDto.setUserId(userId);
        connectionInfoDto.setDisplayName(user.getUsername());
        return connectionInfoDto;
    }

    private MessageDto messageCrafter(String text, UUID userId, String username) {
        String message = username + text;
        return MessageDto.builder()
                .message(message)
                .build();
    }
}