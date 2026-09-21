# =============================================================================
# Dockerfile — Theed em Go
# =============================================================================
# Multi-stage build:
#   - Stage 1 (builder): compila o binário Go estático a partir de src/
#   - Stage 2 (final):   copia só o binário. Imagem final ~15 MB
#
# Estrutura: código da aplicação em src/, go.mod na raiz.
# CGO desabilitado → binário estático, roda em qualquer Linux.
# =============================================================================

# ---------- Stage 1: builder ----------
FROM golang:1.22-alpine AS builder

WORKDIR /build

# Cache de camada: copia só os arquivos de módulo primeiro.
COPY go.mod go.sum ./
RUN go mod download

# Copia o código-fonte da aplicação (src/).
COPY src/ ./src/

# Compila a partir de src/, gera binário estático em /build/app.
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /build/app ./src

# ---------- Stage 2: final ----------
FROM alpine:3.21

# Certificados TLS (útil se o Postgres usar SSL).
RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /build/app /app/app

# Usuário não-root (mesmo padrão do Dockerfile Node anterior).
RUN addgroup -g 1001 -S appgroup && \
    adduser  -S appuser -u 1001 -G appgroup

USER appuser

EXPOSE 3000

CMD ["/app/app"]
