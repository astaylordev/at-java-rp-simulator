package ca.gc.rp.simulator.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.Locale;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home(Locale locale, Model model) {
        model.addAttribute("lang", locale.getLanguage());
        return "index";
    }

    @GetMapping("/profile")
    public String profile(@AuthenticationPrincipal OidcUser oidcUser, Locale locale, Model model) {
        model.addAttribute("claims", oidcUser.getClaims());
        model.addAttribute("name", oidcUser.getFullName());
        model.addAttribute("lang", locale.getLanguage());
        return "profile";
    }
}
