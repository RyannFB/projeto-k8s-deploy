# Projeto Kubernetes - Deploy Fullstack (React + Flask + PostgreSQL)

## Integrantes da Equipe

- Jose Ryann Ferreira de Brito -  20231380032
- Jacksoan Eufrosino de Freitas - 20231380018

# Objetivo do Projeto

Este projeto visa demonstrar o deploy completo de uma aplicação fullstack em um cluster Kubernetes, utilizando:

- **Frontend**: React com Vite (Node.js)
- **Backend**: Flask (Python)
- **Banco de Dados**: PostgreSQL com persistência de dados

A aplicação garante alta disponibilidade com múltiplas réplicas, configuração centralizada via ConfigMap e Secrets, e comunicação externa via NGINX IngressController.

## Arquitetura da Aplicação

```
┌─────────────────────────────────────────────────────────────┐
│                    NAMESPACE: app                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Frontend        │         │  Backend         │          │
│  │  Deployment (2)  │◄───────►│  Deployment (2)  │          │
│  │  Service:        │         │  Service:        │          │
│  │  frontend-svc    │         │  backend-svc     │          │
│  └──────────────────┘         └──────────────────┘          │
│         ▲                              ▲                     │
│         │                              │                     │
│         └──────────────┬───────────────┘                     │
│                        │                                     │
│            ┌───────────▼───────────┐                        │
│            │   Ingress (nginx)     │                        │
│            │   / → frontend        │                        │
│            │   /api → backend      │                        │
│            └───────────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
                        ▼ HTTP
                    localhost:80
                        ▲
        ┌───────────────┴────────────────┐
        │    ConfigMap: backend-config   │
        │    ConfigMap: frontend-config  │
        └────────────────────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                 NAMESPACE: database                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────┐                  │
│  │  PostgreSQL StatefulSet              │                  │
│  │  Service: postgres-service           │                  │
│  │  postgres-db.database.svc.cluster    │                  │
│  │           .local:5432                │                  │
│  └──────────────────┬───────────────────┘                  │
│                     │                                       │
│         ┌───────────▼────────────┐                         │
│         │  PVC: postgres-pvc     │                         │
│         │  Storage: 5Gi          │                         │
│         └────────────────────────┘                         │
│         ┌────────────────────────┐                         │
│         │ Secret: postgres-secret│                         │
│         │ - POSTGRES_USER        │                         │
│         │ - POSTGRES_PASSWORD    │                         │
│         │ - POSTGRES_DB          │                         │
│         └────────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## Estrutura de Arquivos

```
projeto-k8s-deploy/
├── README.md                      # Este arquivo
├── namespace.yaml                 # Namespaces (app e database)
├── frontend/
│   ├── deployment.yaml           # Deployment + Service do React
│   └── configmap.yaml            # ConfigMap com VITE_API_URL
├── backend/
│   ├── deployment.yaml           # Deployment + Service do Flask
│   ├── service.yaml              # Service ClusterIP
│   ├── configmap.yaml            # ConfigMap com variáveis de ambiente
│   ├── app.py                    # Aplicação Flask
│   ├── Dockerfile                # Docker image do backend
│   └── requiriments.txt          # Dependências Python
├── database/
│   ├── statefulset.yaml          # StatefulSet do PostgreSQL
│   ├── pvc.yaml                  # PersistentVolumeClaim
│   └── secret.yaml               # Secret com credenciais
└── ingress/
    └── ingress.yaml              # Configuração do Ingress NGINX
```

## Pré-requisitos

- Kubernetes cluster (Kind, minikube ou similar)
- kubectl configurado
- NGINX Ingress Controller instalado
- Docker (para construir as imagens)

### Instalar NGINX Ingress Controller (Kind)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
```

## Passos para Deploy

### 1. Criar Namespaces

```bash
kubectl apply -f namespace.yaml
```

### 2. Deploy do Banco de Dados

```bash
kubectl apply -f database/secret.yaml
kubectl apply -f database/pvc.yaml
kubectl apply -f database/statefulset.yaml
```

Aguarde o PostgreSQL estar pronto:

```bash
kubectl wait --for=condition=ready pod -l app=postgres -n database --timeout=300s
```

### 3. Deploy do Backend

```bash
kubectl apply -f backend/configmap.yaml
kubectl apply -f backend/deployment.yaml
kubectl apply -f backend/service.yaml
```

Verificar se os pods estão rodando:

```bash
kubectl get pods -n app
kubectl logs -n app -l app=backend
```

### 4. Deploy do Frontend

```bash
kubectl apply -f frontend/configmap.yaml
kubectl apply -f frontend/deployment.yaml
```

### 5. Configurar Ingress

```bash
kubectl apply -f ingress/ingress.yaml
```

Verificar o Ingress:

```bash
kubectl get ingress -n app
kubectl describe ingress app-ingress -n app
```

## Acessando a Aplicação

### Via Ingress (Recomendado)

```bash
# Encontrar o IP do Ingress
kubectl get ingress -n app

# Acessar via navegador
http://localhost/          # Frontend
http://localhost/api/      # Backend API
```

### Via Port-Forward (Testes Locais)

**Frontend:**
```bash
kubectl port-forward -n app svc/frontend-svc 3000:80
# http://localhost:3000
``` 

**Backend:**
```bash
kubectl port-forward -n app svc/backend-svc 5000:80
# http://localhost:5000
# http://localhost:5000/messages
```

**PostgreSQL:**
```bash
kubectl port-forward -n database svc/postgres-service 5432:5432
# psql -h localhost -U messagesuser -d messagesdb
```

## Variáveis de Configuração

### Backend ConfigMap (`backend/configmap.yaml`)

- `DB_HOST`: postgres-db.database.svc.cluster.local
- `DB_PORT`: 5432
- `DB_NAME`: messagesdb
- `API_HOST`: 0.0.0.0
- `API_PORT`: 5000

### Backend Secret (`database/secret.yaml`)

- `POSTGRES_USER`: messagesuser
- `POSTGRES_PASSWORD`: messagespass123
- `POSTGRES_DB`: messagesdb

### Frontend ConfigMap (`frontend/configmap.yaml`)

- `VITE_API_URL`: http://localhost/api

## Endpoints da API

### Health Check

```bash
GET /
Response: {"status": "ok", "service": "backend-flask"}
```

### Get Messages

```bash
GET /messages
Response: ["message1", "message2", ...]
```

### Post Message

```bash
POST /messages
Content-Type: application/json

{
  "content": "Nova mensagem"
}

Response: {"message": "Mensagem salva!"}, 201
```

## Verificação do Deployment

### 1. Status dos Pods

```bash
# Todos os pods
kubectl get pods -A

# Por namespace
kubectl get pods -n app
kubectl get pods -n database
```

### 2. Logs

```bash
# Backend
kubectl logs -n app -l app=backend -f

# Frontend
kubectl logs -n app -l app=frontend -f

# PostgreSQL
kubectl logs -n database -l app=postgres -f
```

### 3. Descrever Recursos

```bash
kubectl describe deployment backend-deploy -n app
kubectl describe service backend-svc -n app
kubectl describe pvc postgres-pvc -n database
```

## Testes Funcionais

### 1. Verificar Conectividade do Backend com PostgreSQL

```bash
kubectl exec -it -n app deployment/backend-deploy -- bash
python -c "import psycopg2; print('PostgreSQL connection OK')"
```

### 2. Testar Endpoint de Saúde

```bash
kubectl port-forward -n app svc/backend-svc 5000:80
curl http://localhost:5000/
```

### 3. Testar Persistência de Dados

```bash
# Enviar uma mensagem
curl -X POST http://localhost:5000/messages \
  -H "Content-Type: application/json" \
  -d '{"content":"Test message"}'

# Buscar mensagens
curl http://localhost:5000/messages

# Reiniciar o pod do backend
kubectl delete pod -n app -l app=backend

# Verificar se a mensagem ainda existe
curl http://localhost:5000/messages
```

## Limpeza

Para remover toda a aplicação:

```bash
# Remover resources
kubectl delete ns app database

# Ou individual
kubectl delete -f ingress/ingress.yaml
kubectl delete -f frontend/
kubectl delete -f backend/
kubectl delete -f database/
kubectl delete -f namespace.yaml
```

## Troubleshooting

### Pod pendente

```bash
kubectl describe pod <pod-name> -n app
# Verificar resource limits, storage, etc.
```

### Erro de conexão com PostgreSQL

```bash
# Verificar Secret
kubectl get secret -n database postgres-secret -o yaml

# Verificar ConfigMap
kubectl get configmap -n app backend-config -o yaml

# Testar conexão
kubectl exec -it -n database postgres-db-0 -- psql -U messagesuser -d messagesdb
```

### Ingress não roteando corretamente

```bash
# Verificar Ingress
kubectl get ingress -n app
kubectl describe ingress app-ingress -n app

# Verificar NGINX Ingress Controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## Notas Importantes

1. **Imagens Docker**: Substitua as imagens padrão por suas próprias imagens do Docker Hub:
   - `backend-deploy`: `seu-usuario/seu-backend:latest`
   - `frontend-deploy`: `seu-usuario/seu-frontend:latest`
      Para essas imagens utilizadas foram feitas com base no repositório base deste projeto: https://github.com/pedrofilhojp/kube-students-projects/tree/main em cima desse repositório foi retirado as imagens do frontend para utilizar no Deployment, mas coube um leve ajuste no ConfigMap para utilizar uma variável que aponta para a URL da API do VITE.
      
2. **Persistência**: O PostgreSQL usa uma PVC que persiste entre reinicializações do cluster.

3. **Alta Disponibilidade**: 
   - Frontend: 2 réplicas
   - Backend: 2 réplicas
   - PostgreSQL: 1 replica (pode ser aumentado com Patroni para HA completo)

4. **Segurança**: Os Secrets contêm credenciais. Em produção, use soluções como Sealed Secrets ou External Secrets Operator.

5. **ConfigMap e Secrets**: Alterações em ConfigMap requerem reinicialização dos pods para serem aplicadas.

## Critérios de Avaliação

- ✅ Deploy funcional de todos os componentes
- ✅ Uso correto de ConfigMap e Secret
- ✅ Configuração adequada do IngressController
- ✅ Volume persistente para o PostgreSQL
- ✅ Alta disponibilidade (réplicas ≥ 2 frontend/backend)
- ✅ Readiness/Liveness Probes configurados
- ✅ Namespace separation (app e database)
---

