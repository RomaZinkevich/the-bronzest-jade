package com.bronzejade.game.controllers;

import com.bronzejade.game.authFilter.ApiUserDetails;
import com.bronzejade.game.domain.dtos.RoomPlayerDto;
import com.bronzejade.game.domain.dtos.SelectCharacterRequest;
import com.bronzejade.game.domain.dtos.RoomDto;
import com.bronzejade.game.domain.dtos.UserDto;
import com.bronzejade.game.domain.entities.Room;
import com.bronzejade.game.domain.entities.RoomPlayer;
import com.bronzejade.game.mapper.RoomMapper;
import com.bronzejade.game.mapper.RoomPlayerMapper;
import com.bronzejade.game.service.AuthService;
import com.bronzejade.game.service.RoomService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
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

    @Mock
    private AuthService authService;

    @Mock
    private Authentication authentication;

    @Mock
    private ApiUserDetails userDetails;

    @InjectMocks
    private RoomController roomController;

    private ObjectMapper objectMapper;
    private UUID testRoomId;
    private UUID testPlayerId;
    private UUID testCharacterId;
    private UserDto testUserDto;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(roomController).build();
        objectMapper = new ObjectMapper();
        objectMapper.findAndRegisterModules();

        testRoomId = UUID.randomUUID();
        testPlayerId = UUID.randomUUID();
        testCharacterId = UUID.randomUUID();

        testUserDto = UserDto.builder()
                .id(testPlayerId)
                .username("testuser")
                .email("test@example.com")
                .build();

        // Mock authentication chain
        when(authentication.getPrincipal()).thenReturn(userDetails);
        when(authService.getUserFromPrincipal(userDetails)).thenReturn(testUserDto);
    }

    @Test
    void selectCharacter_ShouldReturnRoomPlayerDto_WhenValidRequest() throws Exception {
        SelectCharacterRequest request = new SelectCharacterRequest();
        request.setCharacterId(testCharacterId);

        RoomPlayer roomPlayer = RoomPlayer.builder()
                .id(UUID.randomUUID())
                .build();

        RoomPlayerDto roomPlayerDto = new RoomPlayerDto();
        roomPlayerDto.setId(roomPlayer.getId());

        when(roomService.selectCharacter(eq(testRoomId), eq(testPlayerId), eq(testCharacterId)))
                .thenReturn(roomPlayer);
        when(roomPlayerMapper.toDto(roomPlayer)).thenReturn(roomPlayerDto);

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/select-character")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(authentication))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(roomPlayer.getId().toString()));

        verify(roomService, times(1)).selectCharacter(testRoomId, testPlayerId, testCharacterId);
        verify(roomPlayerMapper, times(1)).toDto(roomPlayer);
    }

    @Test
    void selectCharacter_ShouldCallService_WithCorrectParameters() throws Exception {
        SelectCharacterRequest request = new SelectCharacterRequest();
        request.setCharacterId(testCharacterId);

        RoomPlayer roomPlayer = RoomPlayer.builder()
                .id(UUID.randomUUID())
                .build();

        RoomPlayerDto roomPlayerDto = new RoomPlayerDto();
        roomPlayerDto.setId(roomPlayer.getId());

        when(roomService.selectCharacter(any(), any(), any())).thenReturn(roomPlayer);
        when(roomPlayerMapper.toDto(any())).thenReturn(roomPlayerDto);

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/select-character")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(authentication))
                .andExpect(status().isOk());

        verify(roomService).selectCharacter(eq(testRoomId), eq(testPlayerId), eq(testCharacterId));
        verify(roomPlayerMapper).toDto(roomPlayer);
    }

    @Test
    void leaveRoom_ShouldReturnRoomDto_WhenRoomExists() throws Exception {
        Room room = Room.builder()
                .id(testRoomId)
                .build();

        RoomDto roomDto = new RoomDto();
        roomDto.setId(testRoomId);

        when(roomService.leaveRoom(testRoomId, testPlayerId)).thenReturn(room);
        when(roomMapper.toDto(room)).thenReturn(roomDto);

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/leave")
                        .contentType(MediaType.APPLICATION_JSON)
                        .principal(authentication))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(testRoomId.toString()));

        verify(roomService, times(1)).leaveRoom(testRoomId, testPlayerId);
        verify(roomMapper, times(1)).toDto(room);
    }

    @Test
    void leaveRoom_ShouldReturnNullBody_WhenRoomDeleted() throws Exception {
        when(roomService.leaveRoom(testRoomId, testPlayerId)).thenReturn(null);

        mockMvc.perform(post("/api/rooms/" + testRoomId + "/leave")
                        .contentType(MediaType.APPLICATION_JSON)
                        .principal(authentication))
                .andExpect(status().isOk())
                .andExpect(content().string(""));

        verify(roomService, times(1)).leaveRoom(testRoomId, testPlayerId);
        verify(roomMapper, never()).toDto(any());
    }
}