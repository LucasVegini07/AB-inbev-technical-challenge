
# **Desafio AB-inbev**

# Introdução

Este documento descreve a arquitetura, escolhas técnicas e raciocínio no design de um microsserviço escalável e de alto desempenho.

## **Design do Código**

![Layered.png](<https://lh3.googleusercontent.com/pw/AP1GczOm4Fty8jssr_yLUvfHOO_DGIcsy7Vw9hnmwxiUH7R6B_JVILQqOJRrBsLSWsspI4RekgXMlDDlTrq3dgepiIMsIIoLETE_a6YGi07LuIByrkS5O7XWiKjEOqe3DkCG-Eg5BDuEQlJ0Mg2_GsQOtY73Sw=w1271-h1279-s-no-gm?authuser=0>)

O microsserviço utiliza o modelo em camadas, que incentiva a organização, testabilidade e desacoplamento entre os componentes.

### **Justificativa Tecnológica**

**Go (Golang):** Devido à execução de baixa latência. Como nosso objetivo de desempenho é ter todos os tempos de resposta da API abaixo de 500ms, o gerenciamento eficiente de memória e execução compilada do Go nos oferece a velocidade e escalabilidade que precisamos.

**MongoDB:** Escolhido por sua flexibilidade de esquema e capacidade de armazenar documentos JSON nativamente. O MongoDB leva a um crescimento horizontal mais rápido para nosso desenvolvimento, já que nosso modelo de dados não requer quaisquer relacionamentos complexos.

## Arquitetura 

![Architecture.png](<https://lh3.googleusercontent.com/pw/AP1GczPf-xote1l0ArWmPL9PVx27fYGojq32w3opGpgWEJt70RG4w94ampKVqtMpWqxuJEXwEB32T34trBe-Hs9MYHlA1W7zM6LVKLG9vd7FwAXSSVfePuFRWuRwlbVbCwn4Kw2JTH0RKCLE3jJteETbAQTd_g=w905-h1279-s-no-gm?authuser=0>)

A arquitetura de nossa aplicação é escalável e distribuída, que pode ser dividida em componentes principais que são:

1. **Balanceador de Carga:** Envia solicitações entre instâncias de qualquer microsserviço.
2. **Camada API (Go):** Onde as solicitações são validadas e processadas.
3. **Camada de Cache (Redis):** Consultas mais rápidas com menos chamadas para o banco de dados.
4. **Camada de Banco de Dados:**  "Como temos apenas 2 endpoints, conseguimos garantir uma alta disponibilidade e consistência nos dados. 

### Fluxo de Dados

### POST

![Post.png](<https://lh3.googleusercontent.com/pw/AP1GczOJlpBOeaAsuPpvU_0aQ_dOKfrR2BQ1Wta7GnxnxCBMM4xJq14i8oz4qCnEkHyZczBTNCTew73S6Z2zCG5vPzbovcdyrD2mpBP8nFyFDPQv7ic5T8lRp_61bRvuxtcFjrJu_VqG4-1D4GhHb5TpuqWe1w=w837-h1279-s-no-gm?authuser=0>)
### GET

![Get.png](<https://lh3.googleusercontent.com/pw/AP1GczNFvE7SrTIbsxH_KuiClqNlXn_ALMY2ahMFO-9DP5nju1omZIwzdq47hYaX1n02aigjo2Dme-gF0WzLRj7945DR84u_mhj7q_z8R7tSn-SFgQZBBjUKhxDxgFALLC_qfRg8xfhWE-rg7mEh5lL5MGPvbA=w640-h1278-s-no-gm?authuser=0>)

### Containerização 

Vamos containerizar a aplicação com Docker para portabilidade

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

Este Dockerfile utiliza build em múltiplas etapas para gerar uma imagem final leve e segura. A primeira etapa compila a aplicação usando uma imagem base do Go. A segunda utiliza a imagem "scratch", copiando apenas o binário final, o que resulta em uma imagem pequena, sem ferramentas ou dependências adicionais — ideal para inicialização rápida e baixo consumo de memória.

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

## Implantação com Kubernetes

Vamos implantar a aplicação em um cluster do Kubernetes, abaixo estão os arquivos de configuração:

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

Aplicação escalável no uso de CPU. A proposta exige no mínimo 3 pods inicialmente, e tem o potencial de escalar até 10 pods. O autoscale monitora o uso médio de CPU e aumentará o número de réplicas se ultrapassar 80%.

## CI/CD with GitHub Actions

A pipeline CI/CD automatiza as etapas de teste, construção e implantação da aplicação.

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

A pipeline consiste em duas partes: CI (Integração Contínua) e CD (Entrega Contínua). O código é testado e o contêiner é construído e enviado para o Docker Hub durante a fase de CI. Durante a fase de CD, as configurações do Kubernetes são enviadas ao cluster.

## Estratégia de Testes

Seguimos uma Pirâmide de Testes para nossa estratégia de teste. Nosso foco principal foi em testes unitários para garantir que as funcionalidades principais, como validação de entrada e persistência de dados, estavam funcionando conforme o esperado.

Também realizaremos testes de desempenho com ferramentas como K6, que podem simular múltiplos usuários existentes ao mesmo tempo, para garantir que o alvo de resposta abaixo de 500ms esteja sendo alcançado.

Além disso, a observabilidade será fundamental: forneceremos rastreamento em tempo real de métricas da aplicação com Prometheus e Grafana, e configuraremos alertas para alto uso de CPU ou respostas lentas, garantindo a saúde do sistema e ação rápida em caso de falhas.

## Trade-offs e Considerações Futuras

Na nossa arquitetura atual, estamos seguindo uma arquitetura simples, porém eficiente, que consiste em balanceador de carga + API em Go + Redis para caching + MongoDB para armazenamento. Isso também fornece alta disponibilidade, baixa latência e facilidade de operação.

No futuro, pretendemos:

Se o sistema enfrentar um alto volume de solicitações, podemos usar a mensageria com o Kafka para processar assincronamente. Nesse caso, devemos retornar pelo menos o ID do recurso criado (por exemplo, POST) para o cliente, para que ele possa ter uma referência imediata enquanto espera que a informação seja processada no back-end.