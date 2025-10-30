package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.dtos.ConnectionInfoDto;
import com.bronzejade.game.service.RoomPlayerService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class RoomWsController {

    private final SimpMessagingTemplate messagingTemplate;
    private final RoomPlayerService roomPlayerService;

    @MessageMapping("/join")
    public void handleMessage(SimpMessageHeaderAccessor accessor) {
        ConnectionInfoDto connectionInfoDto = retriveConnectionInfo(accessor);
        String message = messageCrafter(" has joined room", connectionInfoDto.getPlayerId());
        messagingTemplate.convertAndSend("/topic/room." + connectionInfoDto.getRoomId(), message);
    }

    private ConnectionInfoDto retriveConnectionInfo(SimpMessageHeaderAccessor accessor) {
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
