FROM golang:1.20-alpine AS builder
LABEL maintainer="Your Name <your.email@example.com>"
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o server main.go

FROM scratch
USER 1001
COPY --from=builder /app/server /server
ENTRYPOINT ["/server"]
EXPOSE 8080