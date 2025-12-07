#!/bin/bash

# Script para build e push das imagens Docker para o Docker Hub
# Uso: ./build-and-push.sh

set -e

# ============================================
# CONFIGURAÇÕES - AJUSTE AQUI
# ============================================
DOCKER_USERNAME="seu-usuario-dockerhub"  # SUBSTITUA pelo seu username do Docker Hub
BACKEND_IMAGE="backend"
FRONTEND_IMAGE="frontend"
VERSION="latest"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Build e Push das Imagens Docker"
echo "==========================================${NC}"

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Erro: Docker não está rodando!${NC}"
    exit 1
fi

# Verificar se está logado no Docker Hub
if ! docker info | grep -q Username; then
    echo -e "${YELLOW}Aviso: Você não está logado no Docker Hub${NC}"
    echo "Por favor, faça login primeiro:"
    echo "  docker login"
    exit 1
fi

# Verificar se os diretórios existem
if [ ! -d "backend" ]; then
    echo -e "${RED}Erro: Diretório 'backend' não encontrado!${NC}"
    exit 1
fi

if [ ! -d "frontend" ]; then
    echo -e "${RED}Erro: Diretório 'frontend' não encontrado!${NC}"
    exit 1
fi

# Verificar se Dockerfile existe no backend
if [ ! -f "backend/Dockerfile" ]; then
    echo -e "${YELLOW}Aviso: Dockerfile não encontrado em backend/${NC}"
    echo "Criando Dockerfile básico para o backend..."
    cat > backend/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
EOF
    echo -e "${GREEN}Dockerfile criado em backend/Dockerfile${NC}"
fi

# Verificar se Dockerfile existe no frontend
if [ ! -f "frontend/Dockerfile" ]; then
    echo -e "${YELLOW}Aviso: Dockerfile não encontrado em frontend/${NC}"
    echo "Criando Dockerfile básico para o frontend..."
    cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
    echo -e "${GREEN}Dockerfile criado em frontend/Dockerfile${NC}"
fi

# Build e Push do Backend
echo -e "\n${YELLOW}[1/2] Build e Push do Backend...${NC}"
cd backend

echo "Fazendo build da imagem: ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}"
docker build -t ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION} .

echo "Fazendo push para Docker Hub..."
docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}

echo -e "${GREEN}✓ Backend publicado: ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}${NC}"
cd ..

# Build e Push do Frontend
echo -e "\n${YELLOW}[2/2] Build e Push do Frontend...${NC}"
cd frontend

echo "Fazendo build da imagem: ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}"
docker build -t ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION} .

echo "Fazendo push para Docker Hub..."
docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}

echo -e "${GREEN}✓ Frontend publicado: ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}${NC}"
cd ..

echo -e "\n${GREEN}=========================================="
echo "Build e Push concluídos com sucesso!"
echo "==========================================${NC}"
echo -e "\n${BLUE}Imagens publicadas:${NC}"
echo "  - ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}"
echo "  - ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}"

echo -e "\n${YELLOW}Próximos passos:${NC}"
echo "1. Certifique-se de que os repositórios estão públicos no Docker Hub"
echo "2. Atualize os arquivos YAML:"
echo "   - backend/deployment.yaml (linha 20)"
echo "   - frontend/deployment.yaml (linha 28)"
echo "3. Execute o deploy: ./deploy.sh"

