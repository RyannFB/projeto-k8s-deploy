# Guia Rápido: Docker Hub em 5 Minutos

## Passo a Passo Simplificado

### 1. Criar Conta no Docker Hub
- Acesse: https://hub.docker.com
- Crie uma conta gratuita
- Anote seu **username**

### 2. Fazer Login no Docker Hub
```bash
docker login
```
Digite seu username e password quando solicitado.

### 3. Atualizar Script com Seu Username
```bash
# Opção A: Editar manualmente build-and-push.sh
# Linha 11: DOCKER_USERNAME="seu-usuario-dockerhub"
# Substitua pelo seu username

# Opção B: Usar script automático
./update-images.sh seu-usuario-dockerhub
```

### 4. Preparar o Código da Aplicação

Você precisa ter:
- **Backend**: Código Flask com `app.py` e `requirements.txt`
- **Frontend**: Código React (Vite ou Create React App)

Se não tiver, o script `build-and-push.sh` criará Dockerfiles básicos automaticamente.

### 5. Build e Push das Imagens
```bash
./build-and-push.sh
```

Este script irá:
1. Verificar se você está logado
2. Criar Dockerfiles se não existirem
3. Fazer build das imagens
4. Publicar no Docker Hub

### 6. Tornar Repositórios Públicos

1. Acesse https://hub.docker.com
2. Vá em "Repositories"
3. Clique em cada repositório (`backend` e `frontend`)
4. Vá em "Settings" → "General"
5. Marque como **Public**

### 7. Atualizar Arquivos YAML (se necessário)

Se você usou o script `update-images.sh`, os arquivos já estão atualizados.
Caso contrário, edite manualmente:

**backend/deployment.yaml** (linha 20):
```yaml
image: seu-usuario-dockerhub/backend:latest
```

**frontend/deployment.yaml** (linha 28):
```yaml
image: seu-usuario-dockerhub/frontend:latest
```

### 8. Deploy no Kubernetes
```bash
./deploy.sh
```

## Comandos Úteis

```bash
# Verificar se está logado
docker info | grep Username

# Ver imagens locais
docker images

# Testar imagem localmente (backend)
docker run -p 5000:5000 seu-usuario-dockerhub/backend:latest

# Testar imagem localmente (frontend)
docker run -p 3000:80 seu-usuario-dockerhub/frontend:latest

# Ver logs do build
docker build --progress=plain -t seu-usuario-dockerhub/backend:latest ./backend
```

## Troubleshooting Rápido

**Erro: "denied: requested access"**
- Verifique se o repositório está público no Docker Hub
- Verifique se fez login: `docker login`

**Erro: "Dockerfile não encontrado"**
- O script criará automaticamente
- Ou crie manualmente seguindo o `DOCKER_GUIDE.md`

**Imagem não encontrada no Kubernetes**
- Aguarde 2-3 minutos após o push
- Verifique se está pública: https://hub.docker.com/r/seu-usuario/backend

## Estrutura Mínima Necessária

```
projeto-k8s-deploy/
├── backend/
│   ├── app.py              # Código Flask
│   ├── requirements.txt    # Dependências Python
│   └── Dockerfile          # (criado automaticamente se não existir)
└── frontend/
    ├── src/                # Código React
    ├── package.json        # Dependências Node
    └── Dockerfile          # (criado automaticamente se não existir)
```

---

**Dica**: Para mais detalhes, consulte `DOCKER_GUIDE.md`

