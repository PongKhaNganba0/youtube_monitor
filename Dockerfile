# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files
COPY pubspec.* ./

# Get dependencies
RUN dart pub get

# Copy source code
COPY . .

# Compile to executable
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Runtime
FROM debian:bullseye-slim

# Install CA certificates for HTTPS
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy compiled binary
COPY --from=build /app/bin/server /app/bin/server

# Create data directory
RUN mkdir -p /app/data

WORKDIR /app

EXPOSE 8080

CMD ["/app/bin/server"]
