# Gensyn 설치 및 실행 가이드

이 저장소는 Gensyn을 쉽게 설치하고 실행할 수 있도록 도와주는 Bash 스크립트를 제공합니다. 스크립트는 Docker와 필요한 패키지를 자동으로 설치하고, Gensyn 서비스를 시작합니다.

## 시스템 요구사항

- **CPU**: 최소 16GB RAM (더 큰 모델이나 데이터셋을 사용할 경우 더 많은 RAM이 권장됩니다).
- **GPU (선택 사항)**: 성능 향상을 위해 지원되는 CUDA 장치 사용 가능:
  - RTX 3090
  - RTX 4090
  - A100
  - H100

## 제공 스크립트

1. **gensyn.sh**: GPU를 사용하여 Gensyn을 설치하고 실행합니다.
   - `runtime: nvidia` 옵션을 포함하여 GPU 지원을 활성화합니다.

2. **gensyn_cpu.sh**: CPU만 사용하여 Gensyn을 설치하고 실행합니다.
   - `runtime: nvidia` 옵션을 제거하여 CPU 전용으로 실행됩니다.

## 설치 및 실행

1. **스크립트 다운로드**:
   - `gensyn.sh` 또는 `gensyn_cpu.sh` 파일을 다운로드합니다.

2. **실행 권한 부여**:
   - 터미널에서 `chmod +x gensyn.sh` (또는 `gensyn_cpu.sh`) 명령어로 실행 권한을 부여합니다.

3. **스크립트 실행**:
   - `./gensyn.sh` (또는 `./gensyn_cpu.sh`) 명령어로 스크립트를 실행합니다.

4. **웹 UI 접속**:
   - 설치가 완료되면 `http://localhost:8080` 주소로 웹 UI에 접속할 수 있습니다.

## 문제 해결

- **Docker 및 Python 설치 문제**: 스크립트는 Docker와 Python이 설치되어 있지 않으면 자동으로 설치합니다.
- **GPU 지원**: GPU가 없다면 `gensyn_cpu.sh` 스크립트를 사용하세요.

## 추가 정보

- **Gensyn 공식 문서**: [GensynAI/rl-swarm](https://github.com/gensyn-ai/rl-swarm)
