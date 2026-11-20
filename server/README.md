# server — Swift + Vapor

The cloud server for the kinetic dither board. There is **one board and one owner**: no accounts, users, device ids or sessions. It keeps a single in-memory board state, relays it to the single board socket, and tells the Pico the time. A shared `BOARD_API_TOKEN` is just a secret so strangers on the internet can't control the board.

The Pico W (Embedded Swift firmware) connects out to it over Wi-Fi; the iOS/macOS apps talk to it for remote control. See [`../docs/app-plan.md`](../docs/app-plan.md).

## Endpoints

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/health` | public | `{"status":"ok"}` |
| `GET` | `/time` | public | `{"unixMillis": 1795168676422, "iso8601": "2026-11-20T09:57:56Z", "utcOffsetSeconds": 0}`. The Pico asks for this on startup and after any power loss. `iso8601` is always the UTC instant. Send `Cache-Control: no-store`. |
| `GET` | `/time?tz=Australia/Perth` | public | Same, with that IANA zone's current offset in `utcOffsetSeconds` (`28800`). `400` for an unknown zone. |
| `GET` | `/v1/board/state` | bearer | The stored state. |
| `PUT` | `/v1/board/state` | bearer | Replaces the state, returns it, and pushes it to the board socket. `400` if invalid. |
| `WS` | `/v1/board/socket` | bearer | The board connects here. It receives the current state on connect and on every `PUT`. A new connection replaces the old one. Messages from the board are ignored for now. |

State (`BoardState`):

```json
{ "power": true, "brightness": 0.5, "mode": "dither", "palette": ["#000000", "#FFFFFF"] }
```

- `brightness` is `0...1`.
- `mode` is `dither`, `ambient`, `music` or `timer`.
- `palette` is 1 to 8 colours, each `#RRGGBB` (stored upper-case).

Socket messages are wrapped so more types can be added later: `{"type":"state","state":{...}}`.

Authenticated routes need `Authorization: Bearer <BOARD_API_TOKEN>`. The Pico's HTTPS support is heavy; if it can't do TLS, put `/time` behind a plain-HTTP route on the proxy. `/health` and `/time` are public.

## Environment variables

Full table in [`ENVIRONMENT.md`](ENVIRONMENT.md); `.env.example` is a template.

| Variable | Notes |
|---|---|
| `BOARD_API_TOKEN` | Required in production, where the server refuses to start without it. Unset in development means no auth, with a warning. |
| `HOST` / `PORT` | Local runs only (defaults `127.0.0.1` / `8080`). The Docker image listens on `0.0.0.0:8080`. |

## Run locally

```sh
cd server
BOARD_API_TOKEN=dev swift run App serve
curl localhost:8080/health
curl -H "Authorization: Bearer dev" localhost:8080/v1/board/state
swift test
```

## Docker / Dokploy

`compose.yaml` has a single `board-server` service. It publishes no ports (`expose: 8080`); Dokploy's Traefik reaches it over the Docker network. It runs as a non-root user with all capabilities dropped. **Run one instance only**: the state and socket are in memory.

```sh
cd server
cp .env.example .env        # set BOARD_API_TOKEN
docker compose up -d --build
docker compose logs -f board-server
docker compose down
```

To try it without a proxy, run `docker run -p 8080:8080 -e BOARD_API_TOKEN=dev board-server` after `docker build -t board-server .`. In Dokploy, set the variables in its environment list and point the domain at `board-server`, port `8080`.

## TODO

- Switch the local DTOs in `Sources/App/BoardModels.swift` to the shared `BoardKit` package.
- Persist the board state (it resets to the default on restart).
- Push notifications.
- Weather / sunrise data for the Ambient mode.
- Run the Docker build on a Linux host (not yet verified on Linux).
