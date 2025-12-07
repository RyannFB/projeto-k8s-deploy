#!/bin/bash

# Script para atualizar os nomes das imagens nos arquivos YAML
# Uso: ./update-images.sh <seu-usuario-dockerhub>

set -e

if [ -z "$1" ]; then
    echo "Uso: ./update-images.sh <seu-usuario-dockerhub>"
    echo "Exemplo: ./update-images.sh joaosilva"
    exit 1
fi

DOCKER_USERNAME="$1"

echo "Atualizando imagens nos arquivos YAML..."
echo "Username do Docker Hub: ${DOCKER_USERNAME}"

# Atualizar backend/deployment.yaml
if [ -f "backend/deployment.yaml" ]; then
    sed -i "s|image: seu-usuario-dockerhub/backend:latest|image: ${DOCKER_USERNAME}/backend:latest|g" backend/deployment.yaml
    echo "✓ backend/deployment.yaml atualizado"
else
    echo "⚠ backend/deployment.yaml não encontrado"
fi

# Atualizar frontend/deployment.yaml
if [ -f "frontend/deployment.yaml" ]; then
    sed -i "s|image: seu-usuario-dockerhub/frontend:latest|image: ${DOCKER_USERNAME}/frontend:latest|g" frontend/deployment.yaml
    echo "✓ frontend/deployment.yaml atualizado"
else
    echo "⚠ frontend/deployment.yaml não encontrado"
fi

# Atualizar build-and-push.sh
if [ -f "build-and-push.sh" ]; then
    sed -i "s|DOCKER_USERNAME=\"seu-usuario-dockerhub\"|DOCKER_USERNAME=\"${DOCKER_USERNAME}\"|g" build-and-push.sh
    echo "✓ build-and-push.sh atualizado"
fi

echo ""
echo "Arquivos atualizados com sucesso!"
echo "Agora você pode executar: ./build-and-push.sh"

