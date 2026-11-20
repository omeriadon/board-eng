# Deployment environment variables

What to put in Dokploy's environment list for `board-server`. `compose.yaml` passes everything in that list to the server through `env_file`, so a new variable needs no change there. This needs Docker Compose 2.24 or newer. `.env.example` is the same list as a template.

There is one board and one owner, so there are no accounts, users or device ids. The token below is just a secret so that strangers can't control the board.

| Variable | Required | Default | Notes |
|---|---|---|---|
| `BOARD_API_TOKEN` | yes, in production | none | The shared bearer token for `/v1/*` and the board socket (`Authorization: Bearer <token>`). `/health` and `/time` stay public. Production (`--env production`, which the image uses) refuses to start without it. In development, unset means no auth, with a warning in the log. An empty value counts as unset. |
| `HOST` | no | `127.0.0.1` | Bind address for a local `swift run`. The image passes `--hostname 0.0.0.0` on its command line, which wins. |
| `PORT` | no | `8080` | Port for a local `swift run`. The image passes `--port 8080`, which wins. Change the proxy's target instead. |

## Behind Dokploy

- Point the domain at service `board-server`, container port `8080`. Nothing is published to the host.
- Run one instance only. The board state and the socket are in memory, so a restart resets the state to its default until persistence is added.
- Terminate TLS at Traefik. The Pico can't easily do HTTPS, so see the README note about `/time`.
