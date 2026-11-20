# The dither board's cloud server. The build context is this folder (server/):
#
#   docker build -t board-server .
#   docker run -p 8080:8080 -e BOARD_API_TOKEN=change-me board-server
#
# The server runs as the unprivileged `board` user and needs no capabilities.

ARG SWIFT_IMAGE=swift:6.4-noble
ARG RUN_IMAGE=ubuntu:noble

# MARK: - Build

FROM ${SWIFT_IMAGE} AS build
WORKDIR /src

COPY . .

# .build lives in a cache mount that outlasts each build, so a change only recompiles what it touches.
# Package.resolved is used as committed, so a deploy never spends time resolving and never picks up a new dependency.
RUN --mount=type=cache,id=board-server-build,target=/src/.build \
	swift build -c release --product App --static-swift-stdlib --force-resolved-versions \
	&& bin="$(swift build -c release --show-bin-path --force-resolved-versions)" \
	&& mkdir /staging \
	&& cp "$bin/App" /staging/ \
	&& find -L "$bin" -maxdepth 1 \( -name '*.bundle' -o -name '*.resources' \) -exec cp -RL {} /staging/ \;

# MARK: - Run

FROM ${RUN_IMAGE}

# tzdata is what /time?tz= looks zones up in. ca-certificates is for any outbound HTTPS later (weather, push).
RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates tzdata \
	&& rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 10001 board \
	&& useradd --system --uid 10001 --gid board --home-dir /nonexistent --no-create-home --shell /usr/sbin/nologin board

WORKDIR /app
COPY --from=build /staging /app

USER board:board
EXPOSE 8080

ENTRYPOINT ["/app/App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
