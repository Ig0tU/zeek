#!/bin/bash

echo "======================================"
echo "Starting AgenticSeek Electron App     "
echo "======================================"

source .env

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "Error: Docker Compose is not installed."
    exit 1
fi

echo "1. Starting backend services (Redis, Searxng, Backend API)..."
$COMPOSE_CMD up -d redis searxng backend

echo "2. Waiting for backend API to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:7777/health > /dev/null; then
        echo "Backend is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: backend failed to start properly after 30 seconds"
        $COMPOSE_CMD logs backend
        exit 1
    fi
    sleep 1
done

echo "3. Starting Electron application..."
cd frontend/agentic-seek-front || exit
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

# Run the electron app (dev mode starts the react server and electron window)
npm run electron:start

echo "Electron app closed. Shutting down backend services..."
cd ../..
$COMPOSE_CMD stop redis searxng backend
echo "Done!"
