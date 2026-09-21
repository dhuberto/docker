# =============================================================================
# Dockerfile — Aplicação Go
# =============================================================================
# Multi-stage build:
#   - Stage 1 (builder): compila o binário Go estático
#   - Stage 2 (final):   copia só o binário. Imagem final ~20 MB
#
# Estrutura: código em src/, go.mod na raiz.
# CGO desabilitado → binário estático, roda em qualquer Linux.
# =============================================================================

# ---------- Stage 1: builder ----------
FROM golang:alpine AS builder

WORKDIR /build

# Cache de camada: copia só os arquivos de módulo primeiro.
COPY go.mod go.sum ./
RUN go mod download

# Copia o código-fonte da aplicação (src/).
COPY src/ ./src/

# Compila o binário estático em /build/go-app.
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /build/go-app ./src

# ---------- Stage 2: final ----------
FROM alpine:3.21

# Certificados TLS (útil se o Postgres usar SSL).
RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /build/go-app /app/go-app

# Usuário não-root (princípio do menor privilégio).
RUN addgroup -g 1001 -S appgroup && \
    adduser  -S appuser -u 1001 -G appgroup

USER appuser

EXPOSE 3000

CMD ["/app/go-app"]
