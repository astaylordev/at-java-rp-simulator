package ca.gc.rp.simulator.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.DefaultOAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestCustomizers;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
            ClientRegistrationRepository clientRegistrationRepository) throws Exception {

        // Force PKCE on confidential client via custom resolver
        DefaultOAuth2AuthorizationRequestResolver resolver =
                new DefaultOAuth2AuthorizationRequestResolver(
                        clientRegistrationRepository, "/oauth2/authorization");
        resolver.setAuthorizationRequestCustomizer(
                OAuth2AuthorizationRequestCustomizers.withPkce());

        http
            .authorizeHttpRequests(a -> a
                .requestMatchers("/", "/error", "/actuator/health").permitAll()
                .anyRequest().authenticated())
            .oauth2Login(o -> o
                .authorizationEndpoint(e -> e.authorizationRequestResolver(resolver))
                .defaultSuccessUrl("/profile", true))
            .oidcLogout(l -> l.backChannel(Customizer.withDefaults()))
            .logout(l -> l.logoutSuccessUrl("/"));

        return http.build();
    }
}
