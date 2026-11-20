# The dither board's cloud server. The build context is the repository root, since the server needs ../shared/BoardKit:
#
#   docker build -f server/Dockerfile -t board-server .
#   docker run -p 8080:8080 -e BOARD_API_TOKEN=change-me -v board-data:/data board-server
#
# The server runs as the unprivileged `board` user (uid 10001) and needs no capabilities.
# Only the files named in server/Dockerfile.dockerignore reach the build.

ARG SWIFT_IMAGE=swift:6.4-noble
ARG RUN_IMAGE=ubuntu:noble

# MARK: - Build

FROM ${SWIFT_IMAGE} AS build
WORKDIR /src

# SwiftPM resolves the path dependency `../shared/BoardKit` from /src/server, so the two folders must sit side by side.
COPY shared/BoardKit shared/BoardKit
COPY server server
WORKDIR /src/server

# The cache id changes whenever the build path does (the old cache was built under /src/.build and breaks the module cache here).
# .build lives in a cache mount that outlasts each build, so a change only recompiles what it touches.
# Package.resolved is used as committed, so a deploy never spends time resolving and never picks up a new dependency.
RUN --mount=type=cache,id=board-server-build-v2,target=/src/server/.build \
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

# The latest state is saved in /data (BOARD_DATA_DIR), which compose mounts as the `board-data` volume.
# A new named volume takes this folder's owner, so the non-root server can write to it.
RUN mkdir -p /data && chown board:board /data && chmod 0700 /data

WORKDIR /app
COPY --from=build /staging /app

ENV BOARD_DATA_DIR=/data

USER board:board
VOLUME /data
EXPOSE 8080

ENTRYPOINT ["/app/App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
