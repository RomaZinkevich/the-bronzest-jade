package com.bronzejade.game.templates;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@Builder
public class Room {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;

    private String code;
    private String participant1;
    private String participant2;

    public Room(Long id, String code, String participant1, String participant2) {
        this.id = id;
        this.code = code;
        this.participant1 = participant1;
        this.participant2 = participant2;
    }

    // Getters
    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public String getParticipant1() {
        return participant1;
    }

    public String getParticipant2() {
        return participant2;
    }

    // Setters
    public void setId(Long id) {
        this.id = id;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public void setParticipant1(String participant1) {
        this.participant1 = participant1;
    }

    public void setParticipant2(String participant2) {
        this.participant2 = participant2;
    }
}
