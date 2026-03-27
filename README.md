# Java RP Simulator

A Spring Boot application that simulates an OIDC Relying Party (RP). Useful for testing OpenID Connect identity providers — it performs a standard authorization code flow with PKCE and displays the resulting ID token claims.

## Features

- Authorization code flow with PKCE
- Back-channel OIDC logout
- Displays all ID token claims on the profile page
- Devcontainer support for VS Code

## Configuration

All configuration is provided via environment variables:

| Variable            | Description                        | Default                |
|---------------------|------------------------------------|------------------------|
| `OIDC_CLIENT_ID`    | Client ID registered with the IdP  | _(required)_           |
| `OIDC_CLIENT_SECRET`| Client secret                      | _(required)_           |
| `OIDC_ISSUER_URI`   | IdP issuer URI                     | _(required)_           |
| `OIDC_SCOPES`       | Comma-separated list of scopes     | `openid,profile,email` |

### Local development

For local development, create `src/main/resources/application-local.yml` (this file is gitignored and should never be committed):

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          oidc-client:
            client-id: your-client-id
            client-secret: your-client-secret
        provider:
          oidc-client:
            issuer-uri: https://your-idp.example.com/oauth2
```

The devcontainer sets `SPRING_PROFILES_ACTIVE=local` automatically, so this file will be picked up when running inside VS Code.

## Running

### With Docker Compose

Copy and edit the environment values, then:

```bash
docker compose up
```

App will be available at http://localhost:8080.

### With Maven

Ensure `src/main/resources/application-local.yml` is configured (see [Local development](#local-development)), then:

```bash
SPRING_PROFILES_ACTIVE=local mvn spring-boot:run
```

### With VS Code Dev Container

Open the project in VS Code and select **Reopen in Container**. The devcontainer includes Java 21, Maven, and Claude Code.

## Endpoints

| Path              | Description                        |
|-------------------|------------------------------------|
| `/`               | Home page (public)                 |
| `/profile`        | ID token claims (requires login)   |
| `/actuator/health`| Health check (public)              |
