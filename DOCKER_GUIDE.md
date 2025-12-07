# Guia Completo: Criando e Publicando Imagens Docker no Docker Hub

Este guia explica passo a passo como criar as imagens Docker do frontend e backend e publicá-las no Docker Hub para uso no Kubernetes.

## Pré-requisitos

1. **Conta no Docker Hub**: Crie uma conta gratuita em [hub.docker.com](https://hub.docker.com)
2. **Docker instalado**: Certifique-se de ter o Docker instalado e rodando
3. **Código da aplicação**: Você precisa ter o código do frontend (React) e backend (Flask)

## Passo 1: Estrutura do Projeto

Assumindo que você tem o código da aplicação, organize assim:

```
projeto-k8s-deploy/
├── frontend/              # Código React
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   └── ...
├── backend/              # Código Flask
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── ...
└── ...
```

## Passo 2: Criar Dockerfile para o Backend (Flask)

Crie um arquivo `Dockerfile` no diretório do backend:

```dockerfile
# backend/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copiar requirements e instalar dependências
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código da aplicação
COPY . .

# Expor porta
EXPOSE 5000

# Comando para iniciar a aplicação
CMD ["python", "app.py"]
```

**Exemplo de `requirements.txt`** (se não tiver):
```txt
Flask==3.0.0
psycopg2-binary==2.9.9
flask-cors==4.0.0
```

**Exemplo de `app.py` básico** (se não tiver):
```python
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)
CORS(app)

# Configuração do banco de dados
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'messages_db'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres')
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200

@app.route('/api/messages', methods=['GET'])
def get_messages():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM messages ORDER BY id DESC')
        messages = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify([dict(msg) for msg in messages]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/messages', methods=['POST'])
def create_message():
    try:
        data = request.get_json()
        message = data.get('message', '')
        
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            'INSERT INTO messages (message) VALUES (%s) RETURNING id',
            (message,)
        )
        message_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'id': message_id, 'message': message}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    host = os.getenv('API_HOST', '0.0.0.0')
    port = int(os.getenv('API_PORT', 5000))
    app.run(host=host, port=port, debug=False)
```

## Passo 3: Criar Dockerfile para o Frontend (React)

Crie um arquivo `Dockerfile` no diretório do frontend:

```dockerfile
# frontend/Dockerfile
# Estágio 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar package.json e package-lock.json
COPY package*.json ./

# Instalar dependências
RUN npm ci

# Copiar código fonte
COPY . .

# Build da aplicação
# A variável VITE_API_URL será injetada em runtime
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Estágio 2: Produção
FROM nginx:alpine

# Copiar arquivos buildados
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração customizada do nginx (opcional)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta
EXPOSE 80

# Nginx já inicia automaticamente
CMD ["nginx", "-g", "daemon off;"]
```

**Nota**: Se você usar Create React App (não Vite), ajuste:
```dockerfile
# Para Create React App
ENV REACT_APP_API_URL=$REACT_APP_API_URL
RUN npm run build
COPY --from=builder /app/build /usr/share/nginx/html
```

## Passo 4: Fazer Login no Docker Hub

```bash
docker login
```

Digite seu username e password do Docker Hub quando solicitado.

## Passo 5: Build e Push das Imagens

### Opção A: Manual (Passo a Passo)

#### Backend:

```bash
# 1. Navegar para o diretório do backend
cd backend

# 2. Fazer build da imagem
# Substitua 'seu-usuario-dockerhub' pelo seu username do Docker Hub
docker build -t seu-usuario-dockerhub/backend:latest .

# 3. Verificar se a imagem foi criada
docker images | grep backend

# 4. Fazer push para o Docker Hub
docker push seu-usuario-dockerhub/backend:latest
```

#### Frontend:

```bash
# 1. Navegar para o diretório do frontend
cd frontend

# 2. Fazer build da imagem
docker build -t seu-usuario-dockerhub/frontend:latest .

# 3. Verificar se a imagem foi criada
docker images | grep frontend

# 4. Fazer push para o Docker Hub
docker push seu-usuario-dockerhub/frontend:latest
```

### Opção B: Usando Script Automatizado

Crie um script `build-and-push.sh` na raiz do projeto:

```bash
#!/bin/bash

# Configurações
DOCKER_USERNAME="seu-usuario-dockerhub"
BACKEND_IMAGE="backend"
FRONTEND_IMAGE="frontend"
VERSION="latest"

echo "=========================================="
echo "Build e Push das Imagens Docker"
echo "=========================================="

# Verificar se está logado no Docker Hub
if ! docker info | grep -q Username; then
    echo "Por favor, faça login no Docker Hub primeiro:"
    echo "  docker login"
    exit 1
fi

# Build e Push do Backend
echo -e "\n[1/2] Build e Push do Backend..."
cd backend
docker build -t ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION} .
docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}
cd ..

# Build e Push do Frontend
echo -e "\n[2/2] Build e Push do Frontend..."
cd frontend
docker build -t ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION} .
docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}
cd ..

echo -e "\n=========================================="
echo "Build e Push concluídos com sucesso!"
echo "=========================================="
echo -e "\nImagens publicadas:"
echo "  - ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${VERSION}"
echo "  - ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${VERSION}"
```

Torne o script executável:
```bash
chmod +x build-and-push.sh
```

Execute:
```bash
./build-and-push.sh
```

## Passo 6: Atualizar os Arquivos YAML do Kubernetes

Após publicar as imagens, atualize os arquivos de deployment:

### Atualizar `backend/deployment.yaml`:

```yaml
# Linha 20
image: seu-usuario-dockerhub/backend:latest
```

### Atualizar `frontend/deployment.yaml`:

```yaml
# Linha 28
image: seu-usuario-dockerhub/frontend:latest
```

## Passo 7: Verificar se as Imagens Estão Públicas

1. Acesse [hub.docker.com](https://hub.docker.com)
2. Faça login na sua conta
3. Vá em "Repositories"
4. Verifique se os repositórios `backend` e `frontend` aparecem
5. Certifique-se de que estão marcados como **Públicos** (Public)

## Dicas e Boas Práticas

### 1. Usar Tags Específicas (Recomendado)

Em vez de sempre usar `:latest`, use tags com versões:

```bash
# Build com versão
docker build -t seu-usuario-dockerhub/backend:v1.0.0 .
docker push seu-usuario-dockerhub/backend:v1.0.0

# Atualizar deployment.yaml
image: seu-usuario-dockerhub/backend:v1.0.0
```

### 2. Multi-stage Build (Já implementado no frontend)

O frontend já usa multi-stage build para reduzir o tamanho da imagem final.

### 3. .dockerignore

Crie arquivos `.dockerignore` para excluir arquivos desnecessários:

**backend/.dockerignore**:
```
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv
.git
.gitignore
README.md
.env
```

**frontend/.dockerignore**:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
dist
build
```

### 4. Testar Localmente Antes do Push

```bash
# Testar backend
docker run -p 5000:5000 \
  -e DB_HOST=localhost \
  -e DB_PORT=5432 \
  -e DB_NAME=test \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  seu-usuario-dockerhub/backend:latest

# Testar frontend
docker run -p 3000:80 \
  -e VITE_API_URL=http://localhost:5000 \
  seu-usuario-dockerhub/frontend:latest
```

### 5. Verificar Tamanho das Imagens

```bash
docker images | grep -E "backend|frontend"
```

Imagens muito grandes podem ser otimizadas usando imagens base menores (alpine).

## Troubleshooting

### Erro: "denied: requested access to the resource is denied"

- Verifique se você fez login: `docker login`
- Verifique se o repositório está público no Docker Hub
- Verifique se o nome da imagem está correto (username/repository)

### Erro: "unauthorized: authentication required"

```bash
# Faça logout e login novamente
docker logout
docker login
```

### Imagem não encontrada no Kubernetes

- Verifique se a imagem está pública no Docker Hub
- Verifique se o nome da imagem no YAML está correto
- Aguarde alguns minutos após o push (pode levar tempo para propagar)

### Build falha

- Verifique se todos os arquivos necessários estão no diretório
- Verifique os logs do build: `docker build --no-cache -t ...`
- Teste localmente antes de fazer push

## Comandos Úteis

```bash
# Listar imagens locais
docker images

# Remover imagem local
docker rmi seu-usuario-dockerhub/backend:latest

# Ver logs de um container
docker logs <container-id>

# Executar comando dentro do container
docker exec -it <container-id> /bin/sh

# Limpar imagens não utilizadas
docker image prune -a
```

## Próximos Passos

Após publicar as imagens:

1. Atualize os arquivos YAML com os nomes corretos das imagens
2. Execute o deploy no Kubernetes: `./deploy.sh`
3. Verifique se os pods conseguem fazer pull das imagens:
   ```bash
   kubectl describe pod <pod-name> -n app-namespace
   ```

---

**Nota**: Lembre-se de substituir `seu-usuario-dockerhub` pelo seu username real do Docker Hub em todos os comandos e arquivos!

