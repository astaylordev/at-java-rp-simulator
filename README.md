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

Either set the environment variables directly, or copy `.env.example` to `.env` and fill in your values (`.env` is gitignored and should never be committed):

```bash
cp .env.example .env
```

Environment variables take precedence over `.env` if both are present.

## Running

### With Docker Compose

```bash
docker compose up
```

App will be available at http://localhost:8080.

### With Maven

```bash
mvn spring-boot:run
```

### With VS Code Dev Container

Copy `.env.example` to `.env` before opening the container. Then open the project in VS Code and select **Reopen in Container**. The devcontainer includes Java 21, Maven, and Claude Code.

## Endpoints

| Path              | Description                        |
|-------------------|------------------------------------|
| `/`               | Home page (public)                 |
| `/profile`        | ID token claims (requires login)   |
| `/actuator/health`| Health check (public)              |
