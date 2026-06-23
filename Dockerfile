# ====================================================
# SmartFleet — Flutter Frontend Dockerfile
# Multi-stage build compiling Flutter to Web and
# serving the compiled files using Nginx.
# ====================================================

# Stage 1: Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Set workspace directory
WORKDIR /app

# Run as root to avoid container permission issues
USER root

# Copy dependencies configuration first for Docker layer caching
COPY pubspec.yaml pubspec.lock ./

# Fetch pub dependencies
RUN flutter pub get

# Copy all project source code
COPY . .

# Build the Web release version
RUN flutter build web --release

# Stage 2: Production stage
FROM nginx:alpine

# Copy built static files from build stage to Nginx directory
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Replace Nginx configuration with our custom config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 (internal Nginx port)
EXPOSE 80

# Run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
