# Guia de Configuração do Cluster Kubernetes

## Problema: "connection refused" ao usar kubectl

Se você recebeu o erro:
```
error: error validating "namespace.yaml": error validating data: failed to download openapi: Get "https://127.0.0.1:XXXXX/openapi/v2?timeout=32s": dial tcp 127.0.0.1:XXXXX: connect: connection refused
```

Isso significa que **não há um cluster Kubernetes rodando**.

## Solução: Criar um Cluster Kind

### 1. Verificar se Kind está instalado

```bash
kind version
```

Se não estiver instalado, instale:
```bash
# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Ou via package manager
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y kind
```

### 2. Verificar se Docker está rodando

```bash
docker ps
```

Se não estiver rodando:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### 3. Criar o Cluster

```bash
kind create cluster --name k8s-project
```

Isso criará um cluster local chamado `k8s-project`.

### 4. Verificar se está funcionando

```bash
kubectl cluster-info
kubectl get nodes
```

### 5. Agora você pode fazer o deploy

```bash
kubectl apply -f namespace.yaml
./deploy.sh
```

## Comandos Úteis do Kind

```bash
# Listar clusters
kind get clusters

# Deletar cluster
kind delete cluster --name k8s-project

# Criar cluster com configuração customizada
kind create cluster --name k8s-project --config kind-config.yaml

# Ver logs do cluster
kind export logs --name k8s-project
```

## Instalar NGINX Ingress Controller

Após criar o cluster, instale o Ingress Controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Aguarde até estar pronto:
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## Verificar Status do Cluster

```bash
# Ver nodes
kubectl get nodes

# Ver pods em todos os namespaces
kubectl get pods --all-namespaces

# Ver serviços
kubectl get svc --all-namespaces

# Verificar se o Ingress Controller está rodando
kubectl get pods -n ingress-nginx
```

## Troubleshooting

### Cluster não inicia

```bash
# Verificar logs do Docker
docker logs k8s-project-control-plane

# Deletar e recriar
kind delete cluster --name k8s-project
kind create cluster --name k8s-project
```

### kubectl não encontra o cluster

```bash
# Ver contextos disponíveis
kubectl config get-contexts

# Usar contexto específico
kubectl config use-context kind-k8s-project
```

### Problemas com Docker

```bash
# Verificar se Docker está rodando
sudo systemctl status docker

# Reiniciar Docker
sudo systemctl restart docker

# Adicionar usuário ao grupo docker (se necessário)
sudo usermod -aG docker $USER
newgrp docker
```

## Próximos Passos

1. ✅ Cluster criado
2. ⏭️ Instalar NGINX Ingress Controller
3. ⏭️ Fazer deploy da aplicação: `./deploy.sh`

---

**Nota**: O cluster Kind é temporário. Se você reiniciar o computador, o cluster continuará funcionando, mas se deletar o container Docker, o cluster será perdido.

