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
        MessageDto message = messageCrafter(" has joined room", connectionInfoDto.getPlayerId());
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/ready")
    public void toggleReady(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        RoomPlayer roomPlayer = roomService.togglePlayerReady(UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        MessageDto message = messageCrafter(" is " + (!roomPlayer.isReady() ? "not " : "") + "ready", connectionInfoDto.getPlayerId());
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    @MessageMapping("/start")
    public void start(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        RoomPlayerDto roomPlayerDto = roomService.startGame(UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        String message = "The game has been started";
        StartGameResponse startGameResponse = new StartGameResponse();
        startGameResponse.setMessage(message);
        startGameResponse.setTurnPlayer(roomPlayerDto);
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), startGameResponse);
    }

    @MessageMapping("/question")
    public void question(String payload, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        gameStateService.submitQuestion(payload, UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        MessageDto msg = messageCrafter(payload,  connectionInfoDto.getPlayerId());
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), msg);
    }

    @MessageMapping("/answer")
    public void answer(String payload, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        gameStateService.submitAnswer(payload, UUID.fromString(connectionInfoDto.getRoomId()), UUID.fromString(connectionInfoDto.getPlayerId()));
        MessageDto msg = messageCrafter(payload,  connectionInfoDto.getPlayerId());
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), msg);
    }

    @MessageMapping("/guess")
    public void guessCharacter(String characterId, SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retrieveConnectionInfo(accessor);
        GuessCharacterResponse response = guessCharacterService.guessCharacter(
                UUID.fromString(connectionInfoDto.getRoomId()),
                UUID.fromString(connectionInfoDto.getPlayerId()),
                UUID.fromString(characterId)
        );
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), response);
    }

    @MessageExceptionHandler
    @SendToUser("/queue/errors")
    public String handleException(Exception ex) {
        return ex.getMessage();
    }

    //Retrieves roomId and playerId from session and checks if playerId is the room (from roomId)
    private ConnectionInfoDto retrieveConnectionInfo(SimpMessageHeaderAccessor accessor) {
        if (accessor.getSessionAttributes() == null) throw new IllegalArgumentException("Session attributes cannot be null");
        String roomId =  (String) accessor.getSessionAttributes().get("roomId");
        String playerId =  (String) accessor.getSessionAttributes().get("playerId");
        if (roomId == null || playerId == null) throw new MessagingException("Room or Player ID is null");
        if (!roomPlayerService.isInRoom(UUID.fromString(roomId), UUID.fromString(playerId))) throw new MessagingException("Player is not in the room");
        ConnectionInfoDto connectionInfoDto = new ConnectionInfoDto();
        connectionInfoDto.setRoomId(roomId);
        connectionInfoDto.setPlayerId(playerId);
        return connectionInfoDto;
    }

    private MessageDto messageCrafter(String text, String playerId) {
        String message = "guest-player-" + playerId.substring(0, 6) + text;
        return MessageDto.builder()
                .message(message)
                .build();
    }
}
