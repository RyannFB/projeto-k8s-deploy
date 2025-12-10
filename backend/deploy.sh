#!/bin/bash
# Script para deploy completo da infraestrutura Kubernetes

set -e

echo "======================================"
echo "🚀 DEPLOY BACKEND KUBERNETES"
echo "======================================"

NAMESPACE="app"
BACKEND_PATH="/home/Spyke/projeto-k8s-deploy/backend"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Verificar se kubectl está instalado
echo -e "\n${YELLOW}[1/6]${NC} Verificando kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl não está instalado. Instale kubectl primeiro.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl encontrado${NC}"

# 2. Verificar cluster
echo -e "\n${YELLOW}[2/6]${NC} Verificando conexão com cluster..."
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cluster não acessível. Verifique sua configuração.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Cluster acessível${NC}"

# 3. Criar namespace
echo -e "\n${YELLOW}[3/6]${NC} Criando namespace '${NAMESPACE}'..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace criado/verificado${NC}"

# 4. Fazer build da imagem Docker
echo -e "\n${YELLOW}[4/6]${NC} Buildando imagem Docker..."
cd ${BACKEND_PATH}
docker build -t backend:latest .
echo -e "${GREEN}✓ Imagem buildada com sucesso${NC}"

# 5. Aplicar manifests Kubernetes
echo -e "\n${YELLOW}[5/6]${NC} Aplicando manifests Kubernetes..."
kubectl apply -f ${BACKEND_PATH}/configmap.yaml
echo -e "${GREEN}✓ ConfigMap aplicado${NC}"

kubectl apply -f ${BACKEND_PATH}/postgres-secret.yaml
echo -e "${GREEN}✓ Secret aplicado${NC}"

kubectl apply -f ${BACKEND_PATH}/deployment.yaml
echo -e "${GREEN}✓ Deployment aplicado${NC}"

kubectl apply -f ${BACKEND_PATH}/service.yaml
echo -e "${GREEN}✓ Service aplicado${NC}"

# 6. Aguardar deployment estar pronto
echo -e "\n${YELLOW}[6/6]${NC} Aguardando deployment ficar pronto..."
kubectl rollout status deployment/backend-deploy -n ${NAMESPACE} --timeout=300s
echo -e "${GREEN}✓ Deployment pronto${NC}"

echo -e "\n======================================"
echo -e "${GREEN}✅ DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
echo -e "======================================"
echo -e "\n${YELLOW}Próximos passos:${NC}"
echo "1. Verificar pods: kubectl get pods -n ${NAMESPACE}"
echo "2. Ver logs: kubectl logs -n ${NAMESPACE} -l app=backend"
echo "3. Acessar serviço: kubectl get svc -n ${NAMESPACE}"
echo "4. Port-forward: kubectl port-forward svc/backend-service 8080:80 -n ${NAMESPACE}"
echo ""
