# Stage 1: Build
FROM golang:1.23 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o booking-service .

# Stage 2: Run (Distroless)
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /app/booking-service .
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/booking-service"]
