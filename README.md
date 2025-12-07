# Projeto Kubernetes - Deploy de Aplicação Fullstack

## Integrantes da Equipe
[Adicione os nomes dos integrantes da equipe aqui]

## Objetivo do Projeto

Este projeto visa realizar o deploy completo de uma aplicação fullstack (React + Flask + PostgreSQL) em um cluster Kubernetes, garantindo:

- Alta disponibilidade com múltiplas réplicas
- Configuração via ConfigMap e Secrets
- Persistência de dados com volumes persistentes
- Acesso externo via Ingress Controller NGINX
- Isolamento de recursos através de namespaces

## Arquitetura da Aplicação

A aplicação é composta por três componentes principais:

1. **Frontend (React)**: Interface do usuário que consome a API do backend
2. **Backend (Flask)**: API REST que expõe endpoints GET e POST para mensagens
3. **Banco de Dados (PostgreSQL)**: Armazena as mensagens de forma persistente

### Estrutura de Namespaces

- **app-namespace**: Contém os componentes da aplicação (frontend e backend)
- **db-namespace**: Contém o banco de dados PostgreSQL

### Componentes Kubernetes

- **Deployments**: Frontend e Backend com 2 réplicas cada (alta disponibilidade)
- **StatefulSet**: PostgreSQL para garantir ordem e identidade estável
- **Services**: ClusterIP para comunicação interna entre componentes
- **Ingress**: NGINX Ingress Controller para acesso externo
- **ConfigMap**: Variáveis de ambiente não sensíveis
- **Secrets**: Credenciais e informações sensíveis
- **PVC**: PersistentVolumeClaim para dados do PostgreSQL

## Estrutura do Projeto

```
projeto-k8s-deploy/
├── README.md                        # Este arquivo
├── namespace.yaml                   # Definição dos namespaces
├── frontend/
│   └── deployment.yaml              # Deployment + Service + ConfigMap do React
├── backend/
│   ├── deployment.yaml              # Deployment + Service do Flask
│   ├── configmap.yaml               # ConfigMap com variáveis de ambiente
│   └── secret.yaml                  # Secret com credenciais do banco
├── database/
│   ├── statefulset.yaml             # StatefulSet do PostgreSQL
│   ├── service.yaml                 # Service do PostgreSQL
│   ├── pvc.yaml                     # PVC para volume persistente
│   └── secret.yaml                  # Secret com credenciais do PostgreSQL
└── ingress/
    └── ingress.yaml                 # Regras de Ingress para acesso externo
```

## Pré-requisitos

Antes de iniciar o deploy, certifique-se de ter:

1. **Kubernetes cluster** (Kind, Minikube, ou outro)
2. **kubectl** instalado e configurado
3. **NGINX Ingress Controller** instalado no cluster
4. **Imagens Docker** do frontend e backend publicadas no Docker Hub

### Instalação do NGINX Ingress Controller (Kind)

Se estiver usando Kind, instale o Ingress Controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Aguarde até que o Ingress Controller esteja pronto:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### Preparação das Imagens Docker

**IMPORTANTE**: Antes de aplicar os manifestos, você precisa:

1. Construir as imagens Docker do frontend e backend
2. Publicar as imagens no Docker Hub (repositório público)
3. Atualizar os arquivos `frontend/deployment.yaml` e `backend/deployment.yaml` com o nome correto da sua imagem

Exemplo:
- Substitua `seu-usuario-dockerhub/backend:latest` pelo seu repositório
- Substitua `seu-usuario-dockerhub/frontend:latest` pelo seu repositório

## Passos para Deploy

### 1. Criar os Namespaces

```bash
kubectl apply -f namespace.yaml
```

Verificar criação:

```bash
kubectl get namespaces
```

### 2. Deploy do Banco de Dados

Aplicar os recursos do PostgreSQL na ordem:

```bash
# 1. Secret com credenciais
kubectl apply -f database/secret.yaml

# 2. PVC para persistência
kubectl apply -f database/pvc.yaml

# 3. StatefulSet e Service
kubectl apply -f database/statefulset.yaml
kubectl apply -f database/service.yaml
```

Verificar status do PostgreSQL:

```bash
kubectl get pods -n db-namespace
kubectl get pvc -n db-namespace
```

### 3. Deploy do Backend

```bash
# 1. ConfigMap e Secret
kubectl apply -f backend/configmap.yaml
kubectl apply -f backend/secret.yaml

# 2. Deployment e Service
kubectl apply -f backend/deployment.yaml
```

Verificar status:

```bash
kubectl get pods -n app-namespace
kubectl get svc -n app-namespace
```

### 4. Deploy do Frontend

```bash
kubectl apply -f frontend/deployment.yaml
```

Verificar status:

```bash
kubectl get pods -n app-namespace
kubectl get svc -n app-namespace
```

### 5. Configurar Ingress

```bash
kubectl apply -f ingress/ingress.yaml
```

Verificar Ingress:

```bash
kubectl get ingress -n app-namespace
```

### 6. Deploy Completo (Alternativa)

Para aplicar todos os recursos de uma vez:

```bash
kubectl apply -f namespace.yaml
kubectl apply -f database/
kubectl apply -f backend/
kubectl apply -f frontend/
kubectl apply -f ingress/
```

## Acesso à Aplicação

### Via Ingress (Recomendado)

Após o deploy, obtenha o endereço do Ingress:

```bash
kubectl get ingress -n app-namespace
```

**Para Kind/Minikube**, você pode precisar configurar o /etc/hosts ou usar port-forward:

```bash
# Obter o IP do nginx ingress controller
kubectl get svc -n ingress-nginx

# Ou usar port-forward
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
```

Acesse a aplicação:

- **Frontend**: `http://localhost/` ou `http://localhost:8080/`
- **Backend API**: `http://localhost/api/` ou `http://localhost:8080/api/`

### Via Port-Forward (Teste)

Para testar componentes individualmente:

```bash
# Frontend
kubectl port-forward -n app-namespace service/frontend-service 3000:80

# Backend
kubectl port-forward -n app-namespace service/backend-service 5000:5000
```

Acesse:
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:5000`

## Verificação do Deploy

### Verificar Status dos Pods

```bash
# Aplicação
kubectl get pods -n app-namespace

# Banco de dados
kubectl get pods -n db-namespace
```

### Verificar Logs

```bash
# Backend
kubectl logs -n app-namespace -l app=backend

# Frontend
kubectl logs -n app-namespace -l app=frontend

# PostgreSQL
kubectl logs -n db-namespace -l app=postgres
```

### Verificar Services

```bash
kubectl get svc -n app-namespace
kubectl get svc -n db-namespace
```

### Verificar ConfigMap e Secrets

```bash
kubectl get configmap -n app-namespace
kubectl get secrets -n app-namespace
kubectl get secrets -n db-namespace
```

### Verificar PVC

```bash
kubectl get pvc -n db-namespace
```

## Testes Funcionais

### Testar Backend

```bash
# Listar mensagens
curl http://localhost/api/messages

# Criar mensagem
curl -X POST http://localhost/api/messages \
  -H "Content-Type: application/json" \
  -d '{"message": "Teste de mensagem"}'
```

### Testar Frontend

Abra o navegador e acesse `http://localhost/` (ou o endereço do seu Ingress).

## Recursos Implementados

### ✅ Funcionalidades Obrigatórias

- [x] Deploy completo da aplicação (frontend + backend + banco de dados)
- [x] Uso correto de ConfigMap e Secret para configurar variáveis da aplicação
- [x] IngressController configurado para expor o frontend e backend via rota /api/
- [x] Volume persistente para PostgreSQL, com PVC separado
- [x] Alta disponibilidade com pelo menos 2 réplicas para frontend e backend
- [x] Namespaces separados para aplicação e banco de dados

### ✅ Funcionalidades Bônus

- [x] Liveness e Readiness Probes configurados em todos os componentes
- [x] Resource limits e requests definidos
- [x] StatefulSet para PostgreSQL (garante ordem e identidade estável)

## Troubleshooting

### Pods não iniciam

```bash
# Verificar eventos
kubectl describe pod <pod-name> -n <namespace>

# Verificar logs
kubectl logs <pod-name> -n <namespace>
```

### Problemas de conexão com banco

```bash
# Verificar se o PostgreSQL está rodando
kubectl get pods -n db-namespace

# Testar conexão do backend
kubectl exec -it -n app-namespace <backend-pod> -- env | grep DB_
```

### Ingress não funciona

```bash
# Verificar se o Ingress Controller está rodando
kubectl get pods -n ingress-nginx

# Verificar regras do Ingress
kubectl describe ingress -n app-namespace
```

### PVC não é criado

```bash
# Verificar StorageClass disponível
kubectl get storageclass

# Se necessário, ajustar o storageClassName no pvc.yaml
```

## Limpeza (Remover Deploy)

Para remover todos os recursos:

```bash
kubectl delete -f ingress/
kubectl delete -f frontend/
kubectl delete -f backend/
kubectl delete -f database/
kubectl delete -f namespace.yaml
```

**ATENÇÃO**: Isso removerá todos os dados do banco de dados. Se quiser manter os dados, não delete o PVC.

## Variáveis de Ambiente

### ConfigMap (Backend)

- `DB_HOST`: Hostname do PostgreSQL
- `DB_PORT`: Porta do PostgreSQL (5432)
- `DB_NAME`: Nome do banco de dados
- `API_HOST`: Host do backend (0.0.0.0)
- `API_PORT`: Porta do backend (5000)

### ConfigMap (Frontend)

- `VITE_API_URL`: URL da API do backend

### Secrets

- `POSTGRES_USER`: Usuário do PostgreSQL
- `POSTGRES_PASSWORD`: Senha do PostgreSQL
- `POSTGRES_DB`: Nome do banco de dados
- `DB_USER`: Usuário para conexão (backend)
- `DB_PASSWORD`: Senha para conexão (backend)

## Referências

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Kind Documentation](https://kind.sigs.k8s.io/)

## Notas Importantes

1. **Imagens Docker**: Certifique-se de atualizar as imagens nos arquivos de deployment antes de aplicar
2. **StorageClass**: Verifique se o cluster possui um StorageClass padrão ou ajuste o `pvc.yaml`
3. **Ingress**: Para ambientes de produção, considere configurar TLS com cert-manager
4. **Secrets**: Em produção, use ferramentas como Sealed Secrets ou External Secrets Operator
5. **Monitoramento**: Considere adicionar Prometheus e Grafana para monitoramento

---

**Data de Criação**: [Data]
**Última Atualização**: [Data]
