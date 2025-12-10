import os
import psycopg2
from flask import Flask, request, jsonify
from flask_cors import CORS


app = Flask(__name__)
# Habilita CORS para permitir que o frontend acesse a API
CORS(app)

# Leitura das Variáveis de Ambiente
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_PORT = os.environ.get('DB_PORT', '5432')
DB_NAME = os.environ.get('DB_NAME', 'postgres')
DB_USER = os.environ.get('DB_USER', 'user')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'password')

def get_db_connection():
    conn = psycopg2.connect(
        host = DB_HOST,
        port = DB_PORT,
        database = DB_NAME,
        user = DB_USER,
        password = DB_PASSWORD
    )
    return conn

def init_db():
    """Cria a tabela se não existir"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('CREATE TABLE IF NOT EXISTS messages (id SERIAL PRIMARY KEY, content TEXT);')
        conn.commit()
        cur.close()
        conn.close()
        print("Banco de dados inicializado com sucesso.")
    except Exception as e:
        print(f"Erro ao conectar ao banco de dados: {e}")


# Rota de Health Check (K8s usa para saber se o pod está vivo)
@app.route('/')
def health():
    return jsonify({"status": "ok", "service": "backend-flask"}), 200


# Endpoint GET e POST para mensagens
@app.route('/messages', methods=['GET', 'POST'])
def messages():
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        if request.method == 'GET':
            cur.execute('SELECT content FROM messages;')
            rows = cur.fetchall()
            messages_list = [row[0] for row in rows]
            return jsonify(messages_list)
        
        elif request.method == 'POST':
            data = request.get_json()
            content = data.get('content')
            cur.execute('INSERT INTO messages (content) VALUES (%s)', (content,))
            conn.commit()
            return jsonify({"message": "Mensagem salva!"}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if 'conn' in locals():
            cur.close()
            conn.close()


if __name__ == '__main__':
    # Cria tabela ao iniciar
    init_db()
    app.run(host='0.0.0.0', port=5000)