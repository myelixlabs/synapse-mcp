# Glama verification Dockerfile for Synapse MCP
# Glama needs the server to start and respond to MCP introspection requests.
# The launcher binary downloads the Burrito-wrapped Elixir runtime on first start,
# so we pre-cache it during the build to avoid timeout during verification.

ARG NODE_IMAGE=node:20-slim

# ─── Build stage: install CLI, launcher, and pre-cache the runtime ──────────────

FROM ${NODE_IMAGE} AS build

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Install the npm CLI then download the native launcher binary
RUN npm install -g @myelixlabs/synapse-mcp@latest && \
    synapse-mcp install --quiet

# Pre-cache the Burrito-wrapped Elixir runtime by starting the launcher briefly.
# This avoids the 30-60s first-run download during Glama's verification.
RUN synapse-mcp --http --port 8585 & \
    PID=$!; \
    for i in $(seq 1 120); do \
      if curl -sf http://127.0.0.1:8585/healthz > /dev/null 2>&1; then \
        echo "Runtime ready after ${i}s"; \
        kill $PID 2>/dev/null; \
        break; \
      fi; \
      sleep 1; \
    done; \
    kill $PID 2>/dev/null; \
    wait $PID 2>/dev/null || true

# ─── Runtime stage ──────────────────────────────────────────────────────────────

FROM ${NODE_IMAGE}

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the launcher binary
COPY --from=build /root/.synapse-mcp/synapse-mcp /root/.synapse-mcp/synapse-mcp

# Copy the pre-cached runtime (Burrito bundle)
COPY --from=build /root/.local/share/synapse-mcp /root/.local/share/synapse-mcp

# Symlink into PATH
RUN ln -s /root/.synapse-mcp/synapse-mcp /usr/local/bin/synapse-server

# Synapse MCP listens on HTTP port 8585
EXPOSE 8585

# Entrypoint: launcher binary starts the Elixir runtime and serves MCP on port 8585
ENTRYPOINT ["synapse-server", "--http", "--port", "8585"]