package com.bronzejade.game.service;

import com.bronzejade.game.repositories.RoomRepository;
import com.bronzejade.game.templates.Room;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class RoomService {
    private RoomRepository roomRepo;

    public RoomService(RoomRepository roomRepo) {
        this.roomRepo = roomRepo;
    }

    public Room createRoom(String participant1) {
        String code = UUID.randomUUID().toString().substring(0, 6);

        Room room = Room.builder().code(code).participant1(participant1).build();

        return roomRepo.save(room);
    }

    public void deleteRoom(Long id) {
        if (!roomRepo.existsById(id)) {
            throw new RuntimeException("Room not found with id: " + id);
        }
        roomRepo.deleteById(id);
    }

    public Room joinRoom(String code, String participant2) {
        Room room = roomRepo.findByCode(code).orElseThrow(() -> new RuntimeException("Room could not be found"));
        if(room.getParticipant2() != null){
            throw new RuntimeException("Room has 2 participants");
        }

        if (participant2.equals(room.getParticipant1())) {
            throw new RuntimeException("This participant is already in the room");
        }

        room.setParticipant2(participant2);
        return roomRepo.save(room);
    }

    public Room getRoom(Long id) {
        return roomRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Room not found"));
    }
}
