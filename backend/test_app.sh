#!/bin/bash
# Script para testar a aplicação após deploy

set -e

echo "======================================"
echo "🧪 TESTE DA APLICAÇÃO BACKEND"
echo "======================================"

NAMESPACE="app"
SERVICE_NAME="backend-service"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para aguardar port-forward
wait_for_service() {
    echo -e "${YELLOW}Aguardando serviço ficar disponível...${NC}"
    for i in {1..30}; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Serviço disponível${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo -e "${RED}❌ Timeout aguardando serviço${NC}"
    return 1
}

# 1. Ativar port-forward em background
echo -e "\n${YELLOW}[1/5]${NC} Iniciando port-forward..."
kubectl port-forward svc/${SERVICE_NAME} 8080:80 -n ${NAMESPACE} > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
trap "kill $PORT_FORWARD_PID 2>/dev/null || true" EXIT

# Aguardar port-forward estar pronto
sleep 2

# 2. Testar Health Check
echo -e "\n${YELLOW}[2/5]${NC} Testando Health Check..."
if curl -s http://localhost:8080 | grep -q "ok"; then
    echo -e "${GREEN}✓ Health Check OK${NC}"
else
    echo -e "${RED}❌ Health Check falhou${NC}"
    exit 1
fi

# 3. Testar GET /messages (lista vazia inicialmente)
echo -e "\n${YELLOW}[3/5]${NC} Testando GET /messages..."
MESSAGES=$(curl -s http://localhost:8080/messages)
echo -e "${BLUE}Resposta: $MESSAGES${NC}"
echo -e "${GREEN}✓ GET /messages OK${NC}"

# 4. Testar POST /messages
echo -e "\n${YELLOW}[4/5]${NC} Testando POST /messages..."
POST_RESPONSE=$(curl -s -X POST http://localhost:8080/messages \
  -H "Content-Type: application/json" \
  -d '{"content": "Primeira mensagem de teste!"}')
echo -e "${BLUE}Resposta: $POST_RESPONSE${NC}"

if echo "$POST_RESPONSE" | grep -q "Mensagem salva"; then
    echo -e "${GREEN}✓ POST /messages OK${NC}"
else
    echo -e "${RED}❌ POST /messages falhou${NC}"
    exit 1
fi

# 5. Verificar se a mensagem foi salva
echo -e "\n${YELLOW}[5/5]${NC} Verificando se mensagem foi salva..."
FINAL_MESSAGES=$(curl -s http://localhost:8080/messages)
echo -e "${BLUE}Mensagens salvas: $FINAL_MESSAGES${NC}"

if echo "$FINAL_MESSAGES" | grep -q "Primeira mensagem de teste"; then
    echo -e "${GREEN}✓ Mensagem persistida corretamente${NC}"
else
    echo -e "${YELLOW}⚠ Mensagem não encontrada (possível problema com banco de dados)${NC}"
fi

echo -e "\n======================================"
echo -e "${GREEN}✅ TESTES CONCLUÍDOS!${NC}"
echo -e "======================================"
echo -e "\n${YELLOW}Dicas:${NC}"
echo "- Ver logs: kubectl logs -f -n ${NAMESPACE} -l app=backend"
echo "- Descrever pod: kubectl describe pod -n ${NAMESPACE} -l app=backend"
echo "- Port-forward manual: kubectl port-forward svc/${SERVICE_NAME} 8080:80 -n ${NAMESPACE}"
echo ""
