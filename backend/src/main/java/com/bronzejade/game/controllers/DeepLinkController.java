package com.bronzejade.game.controllers;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
public class DeepLinkController {
  @GetMapping("/join")
  public String joinPage(@RequestParam String code, Model model) {
    model.addAttribute("code", code);
    model.addAttribute("deepLink", "guesswho://join?code=" + code);
    return "join";
  }
}
