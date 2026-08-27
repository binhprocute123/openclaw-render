# Global ARG for use in FROM instructions
ARG OPENCLAW_VERSION=latest

# Build Go proxy
FROM golang:1.22-bookworm AS proxy-builder

WORKDIR /proxy
COPY proxy/ .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /proxy-bin .

# Extend pre-built OpenClaw with our auth proxy
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}

# Base image ends with USER node; switch to root for setup
USER root

# Add packages for OpenClaw operations + backup restore
RUN apt-get update && apt-get install -y --no-install-recommends \
    ripgrep \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add proxy
COPY --from=proxy-builder /proxy-bin /usr/local/bin/proxy

# Create CLI wrapper
RUN printf '#!/bin/sh\nexec node /app/dist/index.js "$@"\n' > /usr/local/bin/openclaw \
    && chmod +x /usr/local/bin/openclaw

# Add backup/restore startup wrapper
COPY entrypoint-wrapper.sh /usr/local/bin/entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/entrypoint-wrapper.sh

# Keep Node memory suitable for Render Free 512 MB
ENV NODE_OPTIONS="--max-old-space-size=256"

ENV PORT=10000
EXPOSE 10000

# Run as non-root
USER node

# Restore backup first, then start proxy
CMD ["/usr/local/bin/entrypoint-wrapper.sh"]
