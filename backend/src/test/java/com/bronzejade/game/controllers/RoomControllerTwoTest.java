package com.bronzejade.game.controllers;

import com.bronzejade.game.domain.RoomStatus;
import com.bronzejade.game.domain.dtos.LeaveRoomRequest;
import com.bronzejade.game.domain.dtos.RoomPlayerDto;
import com.bronzejade.game.domain.dtos.SelectCharacterRequest;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.mapper.RoomMapper;
import com.bronzejade.game.mapper.RoomPlayerMapper;
import com.bronzejade.game.service.RoomService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class RoomControllerTwoTest {

    private MockMvc mockMvc;

    @Mock
    private RoomService roomService;

    @Mock
    private RoomMapper roomMapper;

    @Mock
    private RoomPlayerMapper roomPlayerMapper;

    @InjectMocks
    private RoomController roomController;

    private ObjectMapper objectMapper;

    // UUIDs for tests
    private UUID testRoomId;
    private UUID testPlayerId;
    private UUID testCharacterId;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(roomController).build();
        objectMapper = new ObjectMapper();
        objectMapper.findAndRegisterModules();

        testRoomId = UUID.randomUUID();
        testPlayerId = UUID.randomUUID();
        testCharacterId = UUID.randomUUID();
    }

    // ===== Tests for selectCharacter API =====

    @Test
    void selectCharacter_ShouldReturnRoomPlayerDto_WhenValidRequest() throws Exception {
        SelectCharacterRequest request = new SelectCharacterRequest();
        request.setPlayerId(testPlayerId);
        request.setCharacterId(testCharacterId);

        RoomPlayer roomPlayer = new RoomPlayer();
        roomPlayer.setUserId(testPlayerId);

        RoomPlayerDto roomPlayerDto = new RoomPlayerDto();
        roomPlayerDto.setUserId(testPlayerId);

        when(roomService.selectCharacter(eq(testRoomId), eq(testPlayerId), eq(testCharacterId)))
                .thenReturn(roomPlayer);
        when(roomPlayerMapper.toDto(roomPlayer)).thenReturn(roomPlayerDto);

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/select-character")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(testPlayerId.toString()));

        verify(roomService, times(1)).selectCharacter(testRoomId, testPlayerId, testCharacterId);
        verify(roomPlayerMapper, times(1)).toDto(roomPlayer);
    }

    @Test
    void selectCharacter_ShouldCallService_WithCorrectParameters() throws Exception {
        SelectCharacterRequest request = new SelectCharacterRequest();
        request.setPlayerId(testPlayerId);
        request.setCharacterId(testCharacterId);

        RoomPlayer roomPlayer = new RoomPlayer();
        when(roomService.selectCharacter(any(), any(), any())).thenReturn(roomPlayer);
        when(roomPlayerMapper.toDto(any())).thenReturn(new RoomPlayerDto());

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/select-character")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        verify(roomService).selectCharacter(eq(testRoomId), eq(testPlayerId), eq(testCharacterId));
        verify(roomPlayerMapper).toDto(roomPlayer);
    }

    // ===== Tests for leaveRoom API =====

    @Test
    void leaveRoom_ShouldReturnRoom_WhenRoomExists() throws Exception {
        LeaveRoomRequest request = new LeaveRoomRequest();
        request.setPlayerId(testPlayerId);

        Room room = new Room();
        room.setId(testRoomId);

        when(roomService.leaveRoom(testRoomId, testPlayerId)).thenReturn(room);

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/leave")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(testRoomId.toString()));

        verify(roomService, times(1)).leaveRoom(testRoomId, testPlayerId);
    }

    @Test
    void leaveRoom_ShouldReturnNullBody_WhenRoomDeleted() throws Exception {
        LeaveRoomRequest request = new LeaveRoomRequest();
        request.setPlayerId(testPlayerId);

        when(roomService.leaveRoom(testRoomId, testPlayerId)).thenReturn(null);

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/leave")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(content().string(""));

        verify(roomService, times(1)).leaveRoom(testRoomId, testPlayerId);
    }
}
