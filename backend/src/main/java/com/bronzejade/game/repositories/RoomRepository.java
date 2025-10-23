package com.bronzejade.game.repositories;

import com.bronzejade.game.templates.Room;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoomRepository extends JpaRepository<Room,Long> {
    Optional<Room> findByCode(String code);
}
