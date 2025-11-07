package com.bronzejade.game.controllers;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
public class HelloWorldController {

    // WebSocket message handler
    @MessageMapping("/hello")
    @SendTo("/topic/greetings")
    public String handleMessage(String message) {
        return "Hello, " + message + "!";
    }

    // WebSocket broadcast handler
    @MessageMapping("/broadcast")
    @SendTo("/topic/greetings")
    public String handleBroadcast(String message) {
        return "Broadcast: " + message;
    }
}
