# Multi-stage build for Go microservice
# Production-ready with security best practices

# Stage 1: Build
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Create non-root user
RUN adduser -D -g '' appuser

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download
RUN go mod verify

# Copy source code
COPY src/ ./

# Build binary
# CGO_ENABLED=0 for static binary
# -ldflags for optimization
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a \
    -o product-service \
    main.go

# Stage 2: Runtime
FROM scratch

# Import from builder
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy binary
COPY --from=builder /build/product-service /app/product-service

# Use non-root user
USER appuser:appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app/product-service", "--health-check"]

# Run
ENTRYPOINT ["/app/product-service"]

# Labels for metadata
LABEL org.opencontainers.image.title="Product Service" \
      org.opencontainers.image.description="E-commerce product catalog microservice" \
      org.opencontainers.image.authors="Your Team" \
      org.opencontainers.image.vendor="Your Company" \
      org.opencontainers.image.version="1.0.0"
