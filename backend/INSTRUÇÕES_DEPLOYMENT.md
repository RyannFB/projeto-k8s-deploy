# 📋 GUIA COMPLETO - RODAR INFRAESTRUTURA K8S

## ✅ ANÁLISE DE ERROS CORRIGIDOS

### 1. **Typo em `requiriments.txt`** ✓
   - **Problema**: Arquivo nomeado incorretamente
   - **Solução**: Renomeado para `requirements.txt`
   - **Afeta**: Dockerfile

### 2. **`service.yaml` vazio** ✓
   - **Problema**: Arquivo vazio sem definição de Service
   - **Solução**: Criado Service do tipo LoadBalancer
   - **Expõe**: Porta 80 → 5000 (porta da aplicação)

### 3. **`imagePullPolicy: Always`** ✓
   - **Problema**: Tenta baixar imagem de registry (não existe)
   - **Solução**: Alterado para `IfNotPresent` (usa imagem local)

### 4. **Imagem Docker não existe** ✓
   - **Problema**: `meu-backend-img:v1` não foi buildada
   - **Solução**: Usar `backend:latest` com build local

### 5. **Variáveis de ambiente incompletas** ✓
   - **Problema**: ConfigMap define `API_HOST` e `API_PORT` mas `app.py` não usa
   - **Solução**: Removidas variáveis não utilizadas

### 6. **Secret com `stringData` em texto plano** ✓
   - **Problema**: Credenciais expostas em texto legível
   - **Solução**: Alterado para `data` com base64 encoding
   - **Valores**:
     - `POSTGRES_USER`: postgres (base64: cG9zdGdyZXM=)
     - `POSTGRES_PASSWORD`: 123456 (base64: MTIzNDU2)

---

## 🚀 INSTRUÇÕES PARA RODAR A INFRAESTRUTURA

### **Pré-requisitos:**
1. Docker instalado
2. Kubernetes cluster rodando (Minikube, Docker Desktop, AKS, EKS, etc.)
3. `kubectl` configurado e conectado ao cluster

### **Opção 1: Usar o script de deploy (Recomendado)**

```bash
# 1. Navegar para o diretório
cd /home/Spyke/projeto-k8s-deploy/backend

# 2. Executar script de deploy
./deploy.sh
```

O script fará:
- ✓ Verificar kubectl
- ✓ Verificar conexão com cluster
- ✓ Criar namespace `app`
- ✓ Fazer build da imagem Docker
- ✓ Aplicar ConfigMap
- ✓ Aplicar Secret
- ✓ Fazer deploy da aplicação
- ✓ Verificar status

### **Opção 2: Deploy manual (passo a passo)**

```bash
# 1. Criar namespace
kubectl create namespace app

# 2. Fazer build da imagem
cd /home/Spyke/projeto-k8s-deploy/backend
docker build -t backend:latest .

# 3. Aplicar ConfigMap (variáveis públicas)
kubectl apply -f configmap.yaml

# 4. Aplicar Secret (credenciais)
kubectl apply -f postgres-secret.yaml

# 5. Deploy da aplicação
kubectl apply -f deployment.yaml

# 6. Expor o serviço
kubectl apply -f service.yaml

# 7. Aguardar deployment estar pronto
kubectl rollout status deployment/backend-deploy -n app --timeout=300s
```

---

## 🌐 COMO ACESSAR A APLICAÇÃO

### **1. Verificar o status do deployment**
```bash
kubectl get pods -n app
kubectl get svc -n app
```

### **2. Opção A: Usar Port-Forward (Recomendado para teste local)**
```bash
kubectl port-forward svc/backend-service 8080:80 -n app
```

Então acesse:
- **Health Check**: http://localhost:8080
- **Listar mensagens**: http://localhost:8080/messages
- **Adicionar mensagem**: POST http://localhost:8080/messages

### **3. Opção B: Acessar direto do Service (se LoadBalancer funcionar)**
```bash
# Obter IP externo
kubectl get svc -n app

# Acessar via IP
http://<EXTERNAL-IP>
```

### **4. Opção C: Acessar via NodePort (em Minikube)**
```bash
# Minikube
minikube service backend-service -n app

# Ou manualmente
kubectl get svc -n app
# Usar NODE_IP:NODE_PORT
```

---

## 🧪 TESTANDO A APLICAÇÃO

### **GET - Listar mensagens:**
```bash
curl http://localhost:8080/messages
```

### **POST - Adicionar mensagem:**
```bash
curl -X POST http://localhost:8080/messages \
  -H "Content-Type: application/json" \
  -d '{"content": "Olá Kubernetes!"}'
```

### **Health Check:**
```bash
curl http://localhost:8080
```

---

## 📊 MONITORAR A APLICAÇÃO

```bash
# Ver logs em tempo real
kubectl logs -f -n app -l app=backend

# Ver logs de um pod específico
kubectl logs <POD_NAME> -n app

# Descrever pod (ver eventos)
kubectl describe pod <POD_NAME> -n app

# Ver métricas de recursos
kubectl top pods -n app

# Dashboard (Minikube)
minikube dashboard
```

---

## 🔍 VERIFICAR SE TUDO ESTÁ OK

```bash
# 1. Verificar se pods estão rodando
kubectl get pods -n app
# Esperado: backend-deploy-XXXXX com status "Running"

# 2. Verificar logs para erros
kubectl logs -n app -l app=backend
# Procurar por "Banco de dados inicializado com sucesso"

# 3. Verificar conexão com banco
# O deploy vai falhar se o banco não estiver acessível
# Verifique se `postgres-db.database.svc.cluster.local` está correto

# 4. Testar endpoint
curl http://localhost:8080
# Esperado: {"status": "ok", "service": "backend-flask"}
```

---

## 🛑 DELETAR A INFRAESTRUTURA

```bash
# Delete tudo
kubectl delete namespace app

# Ou delete recursos individuais
kubectl delete deployment backend-deploy -n app
kubectl delete service backend-service -n app
kubectl delete configmap backend-config -n app
kubectl delete secret postgres-secret -n app
```

---

## ⚠️ POSSÍVEIS PROBLEMAS E SOLUÇÕES

### **Problema: CrashLoopBackOff**
```bash
# Ver logs
kubectl logs -n app -l app=backend

# Causas comuns:
# 1. Banco não acessível (DB_HOST incorreto)
# 2. Credenciais erradas
# 3. Requirements não instaladas
```

### **Problema: Pendente (Pending)**
```bash
# Não há nós disponíveis
kubectl get nodes

# Para Minikube, certifique-se que está rodando
minikube start
```

### **Problema: ImagePullBackOff**
```bash
# A imagem não foi buildada
# Fazer build manualmente
docker build -t backend:latest .
```

### **Problema: ConnectionRefused na porta 5432**
```bash
# O banco PostgreSQL não está acessível
# Verificar:
# 1. Se o banco está rodando
# 2. Se o hostname está correto em configmap.yaml
# 3. Se o namespace do banco é "database"
```

---

## 📁 ESTRUTURA FINAL DOS ARQUIVOS

```
backend/
├── app.py                    # Aplicação Flask
├── Dockerfile                # Build da imagem ✓
├── requirements.txt          # Dependências Python ✓
├── deployment.yaml           # Manifesto K8s (2 replicas) ✓
├── service.yaml              # LoadBalancer Service ✓
├── configmap.yaml            # Variáveis públicas ✓
├── postgres-secret.yaml      # Credenciais (base64) ✓
└── deploy.sh                 # Script de deploy ✓
```

---

## 🎯 RESUMO DO QUE FOI FEITO

✅ Renomeado `requiriments.txt` → `requirements.txt`
✅ Criado `service.yaml` com LoadBalancer
✅ Corrigido `Dockerfile` (referência a requirements.txt)
✅ Corrigido `deployment.yaml` (imagePullPolicy, variáveis)
✅ Corrigido `configmap.yaml` (removidas variáveis não usadas)
✅ Corrigido `postgres-secret.yaml` (base64 encoding)
✅ Criado `deploy.sh` para automatizar o processo

---

**Agora tudo está pronto para fazer o deploy!** 🚀
