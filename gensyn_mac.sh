#!/usr/bin/env bash

# Docker가 설치되어 있는지 확인
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing..."
    brew install --cask docker
    open /Applications/Docker.app
    echo "Docker Desktop을 실행하고 데몬을 활성화하세요."
    exit 1
else
    echo "Docker is already installed."
fi

# Python이 설치되어 있는지 확인
if ! command -v python3 &> /dev/null; then
    echo "Python is not installed. Installing..."
    brew install python3
else
    echo "Python is already installed."
fi

# 필요한 패키지 설치
echo "Installing necessary packages..."
brew install curl git wget lz4 jq make gcc nano automake autoconf tmux htop pkg-config openssl leveldb tar clang ncdu unzip

# GensynAI RL Swarm 저장소 클론
echo "Cloning GensynAI RL Swarm repository..."
if [ -d "rl-swarm" ]; then
    echo "rl-swarm directory already exists. Updating repository..."
    cd rl-swarm
    git pull
else
    git clone https://github.com/gensyn-ai/rl-swarm.git
    cd rl-swarm
fi

# docker-compose.yaml 파일 생성
echo "Creating docker-compose.yaml file..."
mv docker-compose.yaml docker-compose.yaml.old 2>/dev/null

# docker-compose.yaml 내용 복사
cat <<EOF > docker-compose.yaml
version: '3'
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.120.0
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "55679:55679"  # Prometheus metrics (optional)
    environment:
      - OTEL_LOG_LEVEL=DEBUG
    healthcheck:
      test: ["CMD", "grpc_health_probe", "-addr=localhost:4317"]
      interval: 5s
      retries: 5
  swarm_node:
    image: europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2
    command: ./run_hivemind_docker.sh
    runtime: nvidia # GPU가 없으면 이 줄을 제거하세요
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - PEER_MULTI_ADDRS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
      - HOST_MULTI_ADDRS=/ip4/0.0.0.0/tcp/38331
    ports:
      - "38331:38331" # Exposes the swarm node's P2P port
    depends_on:
      - otel-collector
    fastapi:
    build:
      context: .
      dockerfile: Dockerfile.webserver
    environment:
      - OTEL_SERVICE_NAME=rlswarm-fastapi
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
    ports:
      - "8080:8000"
    depends_on:
      - otel-collector
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/healthz"]
      interval: 30s
      retries: 3
EOF

# Docker Compose 실행
echo "Starting Docker Compose services..."
docker-compose up --build -d

# 로그 확인
echo "Checking logs..."
docker-compose logs -f

echo "RL Swarm node and web UI dashboard are now running. Access the web UI at http://localhost:8080"
