package com.bronzejade.game.controllers;

import com.bronzejade.game.service.RoomService;
import com.bronzejade.game.templates.Room;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/rooms")
public class RoomController {
    private final RoomService roomService;

    public RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    @PostMapping
    public Room createRoom(@RequestBody Map<String, String> body) {
        String participant1 = body.get("participant1");
        return roomService.createRoom(participant1);
    }

    @DeleteMapping("/{id}")
    public String deleteRoom(@PathVariable Long id) {
        roomService.deleteRoom(id);
        return "Room with id " + id + " has been deleted successfully";
    }

    @PostMapping("/join")
    public Room joinRoom(@RequestBody Map<String, String> body) {
        String code =  body.get("code");
        String participant2 = body.get("participant2");
        return roomService.joinRoom(code, participant2);
    }

    @GetMapping("/{id}")
    public Room getRoom(@PathVariable Long id) {
        return roomService.getRoom(id);
    }
}
