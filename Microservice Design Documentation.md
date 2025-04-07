
# **Desafio AB-inbev**

# Introdução

Este documento detalha a arquitetura, as escolhas técnicas e a justificativa para o projeto de um microsserviço escalável e de alto desempenho.

## **Design do Código**

![Layered.png](<https://lh3.googleusercontent.com/pw/AP1GczOm4Fty8jssr_yLUvfHOO_DGIcsy7Vw9hnmwxiUH7R6B_JVILQqOJRrBsLSWsspI4RekgXMlDDlTrq3dgepiIMsIIoLETE_a6YGi07LuIByrkS5O7XWiKjEOqe3DkCG-Eg5BDuEQlJ0Mg2_GsQOtY73Sw=w1271-h1279-s-no-gm?authuser=0>)

Durante o desenvolvimento, vamos seguir um padrão arquitetural em camadas, com o propósito de garantir a separação de responsabilidades do sistema conforme a imagem acima. A camada de API se comunica com a camada de serviço/domínio, e a camada de serviço/domínio se comunica com a camada de banco de dados. Essa abordagem proporciona uma maior modularização, facilitando tanto a manutenção do sistema quanto a criação de testes, promovendo um desenvolvimento mais ágil e organizado.


### **Justificativa Tecnológica**

**Go (Golang):** Optamos por essa linguagem devido à sua capacidade de operação com baixa latência. Como precisamos manter o tempo de resposta abaixo de 500ms, o Go se torna a linguagem ideal para o funcionamento do sistema.

**MongoDB:** Já o Mongo foi escolhido pela sua capacidade de armazenar JSON de forma nativa. Como nossos dados não exigem relacionamentos complexos, a escolha por esse banco possibilita um desenvolvimento mais ágil e uma escalabilidade horizontal eficiente.

## Arquitetura 

![Architecture.png](<https://lh3.googleusercontent.com/pw/AP1GczPf-xote1l0ArWmPL9PVx27fYGojq32w3opGpgWEJt70RG4w94ampKVqtMpWqxuJEXwEB32T34trBe-Hs9MYHlA1W7zM6LVKLG9vd7FwAXSSVfePuFRWuRwlbVbCwn4Kw2JTH0RKCLE3jJteETbAQTd_g=w905-h1279-s-no-gm?authuser=0>)
A arquitetura da nossa aplicação segue um modelo escalável e distribuído, composto pelos seguinte componentes:

1. **Load Balancer:** Distribui as requisições entre os servidores, garantindo alta disponibilidade.
2. **API Layer (Go):** Responsável por validar e processar as requisições do sistema.
3. **Cache Layer (Redis):** Otimiza a busca pelas dados minizando o acesso direto ao banco de dados.
4. **Database Layer (MongoDB with Replica Sets):**  "Proporciona alta disponibilidade e consistência. Como teremos apenas dois endpoints, não haverá problemas com concorrência, e o risco de inconsistência será muito menor. Além disso, como os dados não podem ser editados, sua integridade permanecerá intacta após a criação. 

### Data Flow

### POST

![Post.png](<https://lh3.googleusercontent.com/pw/AP1GczOJlpBOeaAsuPpvU_0aQ_dOKfrR2BQ1Wta7GnxnxCBMM4xJq14i8oz4qCnEkHyZczBTNCTew73S6Z2zCG5vPzbovcdyrD2mpBP8nFyFDPQv7ic5T8lRp_61bRvuxtcFjrJu_VqG4-1D4GhHb5TpuqWe1w=w837-h1279-s-no-gm?authuser=0>)
### GET

![Get.png](<https://lh3.googleusercontent.com/pw/AP1GczNFvE7SrTIbsxH_KuiClqNlXn_ALMY2ahMFO-9DP5nju1omZIwzdq47hYaX1n02aigjo2Dme-gF0WzLRj7945DR84u_mhj7q_z8R7tSn-SFgQZBBjUKhxDxgFALLC_qfRg8xfhWE-rg7mEh5lL5MGPvbA=w640-h1278-s-no-gm?authuser=0>)
### Containerization

A aplicação será dockernizada, o que tornará o processo de implantação mais eficiente e simples

### Dockerfile

```yaml
FROM golang:1.20-alpine AS builder
LABEL maintainer="Your Name <your.email@example.com>"
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o server main.go

FROM scratch
USER 1001
COPY --from=builder /app/server /server
ENTRYPOINT ["/server"]
EXPOSE 8080
```

Este Dockerfile usa multi-stage building para criar uma imagem final mais leve e segura. Como a baixa latência é crucial neste projeto, essa abordagem se tornou necessária para otimizar o consumo de recursos.

### Docker Compose

```yaml
version: '3.8'

services:
app:
build: .
ports:
- "8080:8080"
depends_on:
- redis
- mongodb
environment:
REDIS_HOST: redis
MONGO_URI: mongodb://mongodb:27017/mydb

redis:
image: redis:latest

mongodb:
image: mongo:latest
```

## Deployment with Kubernetes

A aplicação será implantada em Kubernetes com os seguintes arquivos de configuração:

### Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ab-inbev-go
spec:
  replicas: 3
  selector:
    matchLabels:
      app: goserver
  template:
    metadata:
      labels:
        app: goserver
    spec:
      containers:
        - name: app
          image: ${{ secrets.DOCKER_HUB_USER }}/ab-inbev:latest
          ports:
            - containerPort: 8080

```

### Service YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ab-inbev-go-service
spec:
  selector:
    app: goserver
  type: ClusterIP
  ports:
    - name: goserver-service
      port: 8080
      targetPort: 8080
      protocol: TCP

```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ab-inbev-go-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ab-inbev-go
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80

```

Este HPA vai garantir a escalabilidade da aplicação com base no uso de CPU. Inicialmente, serão utilizados 3 pods, com possibilidade de escalar para até 10. Quando as réplicas atingirem 80% do uso de CPU, o autoscale acionará a escalabilidade automática. Esses parâmetros poderão ser ajustados conforme identificarmos a necessidade de ampliar ainda mais o projeto.

## CI/CD with GitHub Actions

A pipeline de CI/CD automatiza testes, build e deploy da aplicação.

### Workflow YAML

![GitHub Actions.png](<https://lh3.googleusercontent.com/pw/AP1GczPw-wFCrBuPfAlmmIWzbJvA7J59tzwZRF9LCT2J9g8OjRoHZ65dg3TWl_FoyXQi5mpEvleJ29Oq6ep8XkYlduf5k718dffj7al9_K03lyt0Wcmoc0feHtRmFLN3BJarefkiy6F_jnXKu9iFBTsFyCtaEw=w541-h1278-s-no-gm?authuser=0>)

```yaml
name: ab-inbev-ci-cd-go-workflow

on:
  push:
    branches:
      - main

jobs:
  build-and-push:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/setup-go@v2
        with:
          go-version: 1.15
      - run: go test

      - uses: actions/checkout@v3

      - name: Docker Login
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USER }}
          password: ${{ secrets.DOCKER_HUB_PWD }}

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_HUB_USER }}/ab-inbev:latest

  deploy:
    needs: build-and-push
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3

      - name: Set up Kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.K8S_CONFIG }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      - name: Install kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.29.0'

      - name: Verify cluster access
        run: |
          kubectl cluster-info
          kubectl get nodes

      - name: Deploy to Kubernetes
        run: |
          kubectl apply -f k8s/deployment.yaml --namespace default


```

A pipeline está dividida em duas etapas: CI (Integração Contínua) e CD (Entrega Contínua).

Na etapa de CI, o código é testado automaticamente e o container é construído e enviado para o DockerHub. Na etapa de CD, as configurações do Kubernetes são aplicadas ao cluster para implantar a versão mais recente da aplicação.


## Estratégia de Testes


Adotamos uma estratégia de testes baseada na Pirâmide de Testes, priorizando testes unitários para validar funcionalidades principais, como validação de entradas e persistência de dados.

Embora a versão atual se concentre em testes unitários, planejamos adicionar testes de integração no futuro, conforme a complexidade aumentar.

Também realizaremos testes de desempenho com ferramentas como o K6, simulando múltiplos usuários concorrentes para validar a meta de resposta abaixo de 500ms.

Além disso, a observabilidade será essencial: com Prometheus e Grafana, monitoraremos métricas da aplicação em tempo real e configuraremos alertas para uso de CPU elevado ou lentidão nas respostas, garantindo a saúde do sistema e ação rápida diante de falhas.

## Trade-offs e Considerações Futuras

A arquitetura atual adota uma abordagem simples e eficiente, combinando balanceamento de carga, API em Go, cache com Redis e armazenamento em MongoDB. Essa estrutura garante alta disponibilidade, baixa latência e facilidade operacional.

No futuro, pretendemos:

Implementar particionamento (sharding) no MongoDB.

Utilizar mensageria (como Kafka) para processamentos assíncronos.

Aplicar testes automatizados de carga em ambientes controlados.

Adotar autenticação e autorização com OAuth ou JWT.

Aplicar práticas de observabilidade avançada com OpenTelemetry.

**Microservice Design Documentation**
