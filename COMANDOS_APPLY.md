# Comandos kubectl apply -f para o Projeto

## Aplicar Diretórios Inteiros

Você pode aplicar todos os arquivos YAML de um diretório de uma vez:

```bash
# Aplicar todos os arquivos do diretório database/
kubectl apply -f database/

# Aplicar todos os arquivos do diretório backend/
kubectl apply -f backend/

# Aplicar todos os arquivos do diretório frontend/
kubectl apply -f frontend/

# Aplicar todos os arquivos do diretório ingress/
kubectl apply -f ingress/
```

## Ordem Recomendada de Aplicação

### 1. Namespaces (já criados, mas pode aplicar novamente)
```bash
kubectl apply -f namespace.yaml
```

### 2. Banco de Dados (deve ser primeiro)
```bash
kubectl apply -f database/
```

Isso aplicará na ordem:
- `database/secret.yaml`
- `database/pvc.yaml`
- `database/statefulset.yaml`
- `database/service.yaml`

### 3. Backend
```bash
kubectl apply -f backend/
```

Isso aplicará:
- `backend/configmap.yaml`
- `backend/secret.yaml`
- `backend/deployment.yaml` (que inclui o Service)

### 4. Frontend
```bash
kubectl apply -f frontend/
```

Isso aplicará:
- `frontend/deployment.yaml` (que inclui ConfigMap e Service)

### 5. Ingress
```bash
kubectl apply -f ingress/
```

Isso aplicará:
- `ingress/ingress.yaml`

## Deploy Completo em Uma Linha

Você pode aplicar tudo de uma vez (mas atenção à ordem):

```bash
kubectl apply -f namespace.yaml && \
kubectl apply -f database/ && \
kubectl apply -f backend/ && \
kubectl apply -f frontend/ && \
kubectl apply -f ingress/
```

## Aplicar Múltiplos Diretórios

```bash
# Aplicar vários diretórios de uma vez
kubectl apply -f database/ -f backend/ -f frontend/ -f ingress/
```

## Verificar o que será aplicado (Dry-run)

Antes de aplicar, você pode ver o que seria criado:

```bash
# Ver o que seria aplicado sem realmente aplicar
kubectl apply -f database/ --dry-run=client

# Ver em formato YAML
kubectl apply -f database/ --dry-run=client -o yaml
```

## Comandos Úteis

```bash
# Ver todos os recursos criados
kubectl get all -n app-namespace
kubectl get all -n db-namespace

# Ver recursos específicos
kubectl get pods,svc,deployments -n app-namespace
kubectl get statefulset,pvc,svc -n db-namespace

# Ver logs
kubectl logs -n app-namespace -l app=backend
kubectl logs -n app-namespace -l app=frontend
kubectl logs -n db-namespace -l app=postgres

# Descrever recursos para debug
kubectl describe pod <pod-name> -n app-namespace
kubectl describe ingress app-ingress -n app-namespace
```

## Remover Recursos

```bash
# Remover tudo de um diretório
kubectl delete -f database/
kubectl delete -f backend/
kubectl delete -f frontend/
kubectl delete -f ingress/

# Ou usar o script
./undeploy.sh
```

## Vantagens de Aplicar Diretórios

✅ **Simplicidade**: Um comando aplica vários arquivos
✅ **Ordem automática**: Kubernetes aplica na ordem correta
✅ **Idempotência**: Pode executar várias vezes sem problemas
✅ **Rapidez**: Mais rápido que aplicar arquivo por arquivo

## Observações Importantes

⚠️ **Ordem de dependências**: 
- Database deve ser aplicado antes do backend
- Backend deve estar pronto antes do frontend (opcional, mas recomendado)

⚠️ **Múltiplos recursos no mesmo arquivo**: 
- Se um arquivo tem múltiplos recursos separados por `---`, todos serão aplicados
- Exemplo: `backend/deployment.yaml` tem Deployment e Service juntos

⚠️ **Namespaces**: 
- Certifique-se de que os namespaces existem antes de aplicar recursos que os referenciam

