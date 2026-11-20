# server — Swift + Vapor

The cloud server for the kinetic dither board. There is **one board and one owner**: no accounts, users, device ids or sessions. It keeps the latest board state (saved to disk, so a restart keeps it), relays changes between the apps and the board over one WebSocket, and tells everything the time. A shared `BOARD_API_TOKEN` is just a secret so strangers on the internet can't control the board.

It speaks the same binary wire format as the apps and the Pico firmware, because it uses the shared [`BoardKit`](../shared/BoardKit) package (`BoardMessage`, `StateSync`, `BoardState`). It is a path dependency (`../shared/BoardKit`), so `server/` and `shared/BoardKit/` have to sit side by side, including in Docker and in the deploy mirror. See [`../docs/app-plan.md`](../docs/app-plan.md).

## Endpoints

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/health` | public | `{"status":"ok"}` |
| `GET` | `/time` | public | `{"unixMillis": 1795168676422, "iso8601": "2026-11-20T09:57:56Z", "utcOffsetSeconds": 0}`. `iso8601` is always the UTC instant. Sends `Cache-Control: no-store`. |
| `GET` | `/time?tz=Australia/Perth` | public | Same, with that IANA zone's current offset in `utcOffsetSeconds` (`28800`). `400` for an unknown zone. |
| `GET` | `/v1/board/state` | bearer | The current `BoardState` as JSON (BoardKit's `Codable` form). For Shortcuts, curl and debugging. |
| `PUT` | `/v1/board/state` | bearer | Takes a `BoardState` as JSON, applies it (clamped by `BoardState.bounded()`), sends it to **every** connected socket, and returns the new state as JSON. A malformed body is a `4xx`. |
| `WS` | `/v1/board/socket` | bearer | Binary frames. The apps and the board all connect here. See below. |

The JSON is BoardKit's synthesized `Codable` form: enums are their raw numbers (`"mode": 3` is Timer) and every field is required, so `PUT` the whole object. Easiest is to `GET` it, edit it and `PUT` it back.

Authenticated routes need `Authorization: Bearer <BOARD_API_TOKEN>`. The Pico's HTTPS support is heavy; if it can't do TLS, put `/time` behind a plain-HTTP route on the proxy. `/health` and `/time` are public.

## The socket

Every frame is binary and holds exactly one `BoardMessage.encoded()`. Frames that don't decode (wrong version, truncated, trailing bytes, unknown type, text frames) are skipped: nothing is sent back and the socket stays open. Every authenticated socket is just a client; there is no "board" role.

- **On connect**, the server sends `time(now, utcOffset)` (`?tz=Australia/Perth` sets the offset; UTC if absent or unknown), then the current `state`, then the latest `artwork` and `status` if it has any.
- **`state`**: applied through `StateSync` (a duplicate or older revision is dropped). If it was applied, it is saved and the original message is sent to every *other* socket.
- **`requestState`**: the sender gets the current `state`, plus the latest `artwork` if any.
- **`artwork`**: stored as the latest and sent to every other socket.
- **`status`**: stored as the latest and sent to every other socket.
- **`command`**: sent to every other socket. Not stored.
- **`time`** from a client: ignored.
- The server pings every 20 seconds so proxies keep the connection open.

A change made with `PUT /v1/board/state` is stamped with the server's origin (`255`) and a counter one higher than the newest revision, and goes to all sockets.

## Environment variables

Full table in [`ENVIRONMENT.md`](ENVIRONMENT.md); `.env.example` is a template.

| Variable | Notes |
|---|---|
| `BOARD_API_TOKEN` | Required in production, where the server refuses to start without it. Unset in development means no auth, with a warning. |
| `BOARD_DATA_DIR` | Where the latest state is saved (`state.bin`), default `./data` locally and `/data` in Docker. Created if missing. |
| `HOST` / `PORT` | Local runs only (defaults `127.0.0.1` / `8080`). The Docker image listens on `0.0.0.0:8080`. |

## Run locally

```sh
cd server
BOARD_API_TOKEN=dev swift run App serve
curl localhost:8080/health
curl -H "Authorization: Bearer dev" localhost:8080/v1/board/state
swift test       # includes tests that open real sockets on a random local port
```

## Docker / Dokploy

`compose.yaml` has a single `board-server` service. It publishes no ports (`expose: 8080`); Dokploy's Traefik reaches it over the Docker network. It runs as a non-root user (uid 10001) with all capabilities dropped, and mounts the `board-data` volume at `/data` for the saved state. **Run one instance only.**

The build context is the **repository root** (compose uses `context: ..`, `dockerfile: server/Dockerfile`) because the image builds `shared/BoardKit` as well. `server/Dockerfile.dockerignore` (read by BuildKit next to the Dockerfile) lets only `server/` and `shared/BoardKit/` into the build. Keep the `Tests/` folders in it: SwiftPM reports "overlapping sources" if they are missing.

```sh
cd server
cp .env.example .env        # set BOARD_API_TOKEN
docker compose up -d --build
docker compose logs -f board-server
docker compose down         # keeps the board-data volume
```

To try it without a proxy, from the repository root: `docker build -f server/Dockerfile -t board-server .`, then `docker run -p 8080:8080 -e BOARD_API_TOKEN=dev -v board-data:/data board-server`. In Dokploy, set the variables in its environment list and point the domain at `board-server`, port `8080`.

## TODO

- Push notifications.
- Weather / sunrise data for the Ambient mode.
- Run the Docker build on a Linux host (not yet verified on Linux).

## Deploying (Dokploy)

Same setup as Ergo. `.github/workflows/mirror-server.yml` (repo root) copies `server/` and `shared/BoardKit/` to the public repo
[`omeriadon/BoardServerDeploy`](https://github.com/omeriadon/BoardServerDeploy) on every push to `main` that touches
`server/**` or `shared/**`, then asks Dokploy to redeploy. The mirror has the same layout as this repo for those two folders,
which is what the Docker build and the `../shared/BoardKit` path dependency need.

- Secrets in `board-eng`: `SERVER_MIRROR_KEY` (write deploy key on the mirror) and `DOKPLOY_API_KEY`.
- Repo variable `DOKPLOY_COMPOSE_ID`: the Dokploy compose app's ID. Until it's set, the workflow only mirrors.
- Dokploy compose app: repo `omeriadon/BoardServerDeploy`, branch `main`, compose path `server/compose.yaml`,
  environment `BOARD_API_TOKEN=<openssl rand -hex 32>`, domain → service `board-server`, port `8080`.
