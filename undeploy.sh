#!/bin/bash

# Script para remover o deploy da aplicação Kubernetes
# Uso: ./undeploy.sh

set -e

echo "=========================================="
echo "Removendo Deploy da Aplicação Kubernetes"
echo "=========================================="

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

read -p "Tem certeza que deseja remover todos os recursos? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 1
fi

# Remover recursos na ordem inversa
echo -e "\n${YELLOW}Removendo Ingress...${NC}"
kubectl delete -f ingress/ --ignore-not-found=true

echo -e "\n${YELLOW}Removendo Frontend...${NC}"
kubectl delete -f frontend/ --ignore-not-found=true

echo -e "\n${YELLOW}Removendo Backend...${NC}"
kubectl delete -f backend/ --ignore-not-found=true

echo -e "\n${YELLOW}Removendo Banco de Dados...${NC}"
kubectl delete -f database/ --ignore-not-found=true

echo -e "\n${YELLOW}Removendo Namespaces...${NC}"
kubectl delete -f namespace.yaml --ignore-not-found=true

echo -e "\n${GREEN}=========================================="
echo "Recursos removidos com sucesso!"
echo "==========================================${NC}"

echo -e "\n${YELLOW}Nota:${NC} O PVC foi mantido para preservar os dados."
echo "Para remover o PVC também, execute:"
echo "  kubectl delete pvc postgres-pvc -n db-namespace"

