# Como Acessar a Aplicação - IPs e Endpoints

## 📍 IPs dos Recursos

### IPs dos Pods

```bash
# Ver IPs de todos os pods
kubectl get pods -n app-namespace -o wide

# Ver apenas os IPs
kubectl get pods -n app-namespace -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'
```

**IPs atuais dos pods:**
- `backend-57ff6cc955-hh67r`: 10.244.0.11
- `backend-57ff6cc955-kjslk`: 10.244.0.10
- `frontend-86cd5f7894-6fxtt`: 10.244.0.12
- `frontend-86cd5f7894-jqx8l`: 10.244.0.13

### IP do Node

```bash
kubectl get nodes -o wide
```

**IP do node:**
- `k8s-project-control-plane`: 172.20.0.2 (INTERNAL-IP)

### IPs dos Services (ClusterIP)

```bash
kubectl get svc -n app-namespace -o wide
```

**IPs dos services:**
- `backend-service`: 10.96.131.24:5000
- `frontend-service`: 10.96.195.45:80

### IP do Ingress

```bash
kubectl get ingress -n app-namespace
```

**Ingress:**
- `app-ingress`: ADDRESS: localhost, PORT: 80

## 🌐 Formas de Acessar a Aplicação

### 1. Via Ingress (Recomendado - Acesso Externo)

O Ingress já está configurado e aponta para `localhost`.

```bash
# Verificar o IP do Ingress Controller
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Acessar via Ingress (Kind precisa de port-forward)
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
```

Depois acesse no navegador:
- **Frontend**: http://localhost:8080/
- **Backend API**: http://localhost:8080/api/

### 2. Via Port-Forward (Teste Rápido)

#### Frontend
```bash
kubectl port-forward -n app-namespace service/frontend-service 3000:80
```
Acesse: http://localhost:3000

#### Backend
```bash
kubectl port-forward -n app-namespace service/backend-service 5000:5000
```
Acesse: http://localhost:5000

#### Port-forward direto do pod
```bash
# Frontend
kubectl port-forward -n app-namespace pod/frontend-86cd5f7894-6fxtt 3000:80

# Backend
kubectl port-forward -n app-namespace pod/backend-57ff6cc955-hh67r 5000:5000
```

### 3. Via ClusterIP (Apenas dentro do cluster)

Os IPs dos services são acessíveis apenas dentro do cluster:

- **Backend**: `http://10.96.131.24:5000`
- **Frontend**: `http://10.96.195.45:80`

Para acessar de dentro do cluster (por exemplo, de outro pod):
```bash
# Testar de dentro de um pod
kubectl run curl-test --image=curlimages/curl:latest -it --rm --restart=Never -- \
  curl http://backend-service.app-namespace.svc.cluster.local:5000
```

### 4. Via DNS do Service (Recomendado dentro do cluster)

Dentro do cluster, use o DNS do service:

- **Backend**: `http://backend-service.app-namespace.svc.cluster.local:5000`
- **Frontend**: `http://frontend-service.app-namespace.svc.cluster.local:80`

Ou versão curta (mesmo namespace):
- **Backend**: `http://backend-service:5000`
- **Frontend**: `http://frontend-service:80`

### 5. Acessar IP Direto do Pod (Não recomendado)

Os IPs dos pods mudam quando são recriados. Use apenas para debug:

```bash
# Executar comando dentro do pod
kubectl exec -it -n app-namespace frontend-86cd5f7894-6fxtt -- sh

# De dentro do pod, testar outro pod
curl http://10.244.0.10:5000  # IP do backend pod
```

## 🔍 Comandos para Descobrir IPs

### Ver todos os IPs de uma vez
```bash
echo "=== PODs ===" && \
kubectl get pods -n app-namespace -o wide && \
echo -e "\n=== Services ===" && \
kubectl get svc -n app-namespace -o wide && \
echo -e "\n=== Ingress ===" && \
kubectl get ingress -n app-namespace && \
echo -e "\n=== Nodes ===" && \
kubectl get nodes -o wide
```

### Ver IP específico de um pod
```bash
kubectl get pod <pod-name> -n app-namespace -o jsonpath='{.status.podIP}'
```

### Ver IP do service
```bash
kubectl get svc <service-name> -n app-namespace -o jsonpath='{.spec.clusterIP}'
```

### Ver IP do node
```bash
kubectl get node <node-name> -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
```

## 🧪 Testar Conectividade

### Testar backend de dentro do cluster
```bash
# Criar pod temporário para testar
kubectl run test-curl --image=curlimages/curl:latest -it --rm --restart=Never -n app-namespace -- \
  curl http://backend-service:5000/health
```

### Testar frontend de dentro do cluster
```bash
kubectl run test-curl --image=curlimages/curl:latest -it --rm --restart=Never -n app-namespace -- \
  curl http://frontend-service:80
```

### Testar do host (via port-forward)
```bash
# Em um terminal, fazer port-forward
kubectl port-forward -n app-namespace service/backend-service 5000:5000

# Em outro terminal, testar
curl http://localhost:5000/health
```

## 📝 Resumo dos Endpoints

| Método | Frontend | Backend |
|--------|----------|---------|
| **Ingress** | http://localhost:8080/ | http://localhost:8080/api/ |
| **Port-Forward (Service)** | http://localhost:3000 | http://localhost:5000 |
| **Port-Forward (Pod)** | http://localhost:3000 | http://localhost:5000 |
| **ClusterIP (dentro do cluster)** | http://10.96.195.45:80 | http://10.96.131.24:5000 |
| **DNS (dentro do cluster)** | http://frontend-service:80 | http://backend-service:5000 |

## ⚠️ Observações Importantes

1. **IPs dos Pods mudam**: Quando um pod é recriado, ele recebe um novo IP. Use Services para acesso estável.

2. **ClusterIP não é acessível externamente**: Os IPs dos services (10.96.x.x) só funcionam dentro do cluster.

3. **Kind precisa de port-forward**: Como o Kind roda em containers, você precisa usar port-forward para acessar do host.

4. **Ingress no Kind**: O Ingress Controller precisa de port-forward para expor a porta 80.

## 🚀 Acesso Rápido (Script)

Crie um script para facilitar o acesso:

```bash
#!/bin/bash
# acessar-app.sh

echo "Escolha como acessar:"
echo "1) Frontend via port-forward (porta 3000)"
echo "2) Backend via port-forward (porta 5000)"
echo "3) Ingress via port-forward (porta 8080)"
read -p "Opção: " opcao

case $opcao in
  1)
    kubectl port-forward -n app-namespace service/frontend-service 3000:80
    ;;
  2)
    kubectl port-forward -n app-namespace service/backend-service 5000:5000
    ;;
  3)
    kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
    ;;
  *)
    echo "Opção inválida"
    ;;
esac
```

