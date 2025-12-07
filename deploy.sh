#!/bin/bash

# Script de deploy para a aplicação Kubernetes
# Uso: ./deploy.sh

set -e

echo "=========================================="
echo "Deploy da Aplicação Kubernetes"
echo "=========================================="

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para verificar se o comando foi executado com sucesso
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        exit 1
    fi
}

# 1. Criar namespaces
echo -e "\n${YELLOW}[1/6]${NC} Criando namespaces..."
kubectl apply -f namespace.yaml
check_status "Namespaces criados"

# 2. Deploy do banco de dados
echo -e "\n${YELLOW}[2/6]${NC} Deployando banco de dados..."
kubectl apply -f database/secret.yaml
kubectl apply -f database/pvc.yaml
kubectl apply -f database/statefulset.yaml
kubectl apply -f database/service.yaml
check_status "Banco de dados deployado"

# Aguardar PostgreSQL estar pronto
echo -e "\n${YELLOW}Aguardando PostgreSQL estar pronto...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n db-namespace --timeout=120s
check_status "PostgreSQL está pronto"

# 3. Deploy do backend
echo -e "\n${YELLOW}[3/6]${NC} Deployando backend..."
kubectl apply -f backend/configmap.yaml
kubectl apply -f backend/secret.yaml
kubectl apply -f backend/deployment.yaml
check_status "Backend deployado"

# 4. Deploy do frontend
echo -e "\n${YELLOW}[4/6]${NC} Deployando frontend..."
kubectl apply -f frontend/deployment.yaml
check_status "Frontend deployado"

# 5. Deploy do Ingress
echo -e "\n${YELLOW}[5/6]${NC} Configurando Ingress..."
kubectl apply -f ingress/ingress.yaml
check_status "Ingress configurado"

# 6. Verificar status
echo -e "\n${YELLOW}[6/6]${NC} Verificando status dos pods..."
echo -e "\n${YELLOW}Pods no namespace app-namespace:${NC}"
kubectl get pods -n app-namespace

echo -e "\n${YELLOW}Pods no namespace db-namespace:${NC}"
kubectl get pods -n db-namespace

echo -e "\n${YELLOW}Services:${NC}"
kubectl get svc -n app-namespace
kubectl get svc -n db-namespace

echo -e "\n${YELLOW}Ingress:${NC}"
kubectl get ingress -n app-namespace

echo -e "\n${GREEN}=========================================="
echo "Deploy concluído com sucesso!"
echo "==========================================${NC}"

echo -e "\n${YELLOW}Para verificar os logs:${NC}"
echo "  Backend:  kubectl logs -n app-namespace -l app=backend"
echo "  Frontend: kubectl logs -n app-namespace -l app=frontend"
echo "  Postgres: kubectl logs -n db-namespace -l app=postgres"

echo -e "\n${YELLOW}Para acessar via port-forward:${NC}"
echo "  Frontend: kubectl port-forward -n app-namespace service/frontend-service 3000:80"
echo "  Backend:  kubectl port-forward -n app-namespace service/backend-service 5000:5000"

