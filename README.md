# Microsserviço de Alta Performance

Este projeto apresenta uma arquitetura de microserviços centrada no desempenho, que é escalável e fácil de manter.

## 1. Visão Geral

Este microserviço possui duas rotas principais:

- `POST /resource`: Para criar um novo recurso.
- `GET /resource/:id`: Obter um recurso pelo ID.

### Tecnologias Utilizadas

- **Go**
- **MongoDB**
- **Redis**
- **Docker**
- **Kubernetes**

## 2. Como Executar

### Ambiente Local

Certifique-se de ter Docker e Docker Compose instalados.

Para iniciar o ambiente local:

```bash
docker-compose up --build