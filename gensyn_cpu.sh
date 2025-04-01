#!/bin/bash

# Docker가 설치되어 있는지 확인
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing..."
    # Docker 설치
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    # DockerCompose 설치
    sudo apt-get install docker-compose-plugin -y
    # Docker 실행 테스트
    sudo docker run hello-world
    # Docker를 sudo 없이 실행할 수 있도록 사용자 추가
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed."
fi

# Python이 설치되어 있는지 확인
if ! command -v python3 &> /dev/null; then
    echo "Python is not installed. Installing..."
    # Python 설치
    sudo apt-get install python3 python3-pip -y
else
    echo "Python is already installed."
fi

# 필요한 패키지 설치
echo "Installing necessary packages..."
sudo apt-get update
sudo apt-get install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

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
      - "4317:4317" # OTLP gRPC
      - "4318:4318" # OTLP HTTP
      - "55679:55679" # Prometheus metrics (optional)
    environment:
      - OTEL_LOG_LEVEL=DEBUG
  swarm_node:
    image: europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2
    command: ./run_hivemind_docker.sh
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
      - INITIAL_PEERS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
    ports:
      - "18080:8000" # Maps port 8080 on the host to 8000 in the container
    depends_on:
      - otel-collector
      - swarm_node
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/healthz"]
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
