
# **Microservice Design Documentation**

# Introduction

This document describes the architecture, technical decisions, and rationale for designing a scalable, high-performance microservice.

## **Code Design**

![Layered.png](<https://media-hosting.imagekit.io/eb8e626d36d54e02/Layered.png?Expires=1838379311&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=Fjzs8hv~wdKxePkJzlaigVEWY9fZ4c8~4Jb6fp8gH3YMyFYQemyzfXS~o6V~OdcccYH4QM6XBcHJrRrE~~JNN7KaqccAmf4bAY9JI0XXAflVPeYHFOYbaCnCmvdruU4auzor2dD2zFzEEAhjS6k0Q5JA7fExL9mVAJ8EPrBPcRrlFoR97SwOywZ5CJpy5smXYjt5Jk7FSWl9~QD5Mejp9DbQFKQrj7bopLNjkKlZxzKtUvm9Mcyv9DgJj-L8yLGnxjMoU8JjTJ6hus5wq8gSxsynivrcexmNY25JuoyljNnpysMdzImiK2WwqB7Ob~vkyMxY~Co8XE34d93HR98MRQ__>)

Microservice follows a layered code design, ensuring modularity, maintainability, and separation of concerns

### **Technology Justification**

**Go (Golang)** was selected for its high concurrency support and low-latency execution. Given our performance goal of keeping API response times under 500ms, Go’s efficient memory management and compiled execution provide the necessary speed and scalability.

**MongoDB** was chosen for its schema flexibility and ability to store JSON documents natively. Since our data model does not require complex relationships, MongoDB enables faster development and efficient horizontal scaling

## Architecture

![Architecture.png](<https://media-hosting.imagekit.io/eeadbff1e58e4085/Architecture.png?Expires=1838379449&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=BrsS~0ZrSPDHpjBW~spWVXq5KgC7MVGCUQcy2s7vR45LQhR4wUP85kuXgUpSOaJHr3rKeXISJGz1sfyL05wGDOWuhFzMDYvuhFnrY9ZBi2M2R-qO6fpEobjE1UQj5EDwdm3bc7O1P6sAIlGUgEXYiud4XSCURPZfxcWMRRMR9gogmKZgvNfWQiMDO0wcpz9IBck-CxwXuV2QmIYUYAXzBVu7L8LT6d1P6U7yZddRsBymlReGCiTDEL5MEUk6AWLd2xm9MUWV2KTADNIfcDYZtNdh7I6yhK~Muavp4iJS5~-I0uvvgOao-uAxbOUBFfrlsWmGHmgzEBoPmzPe-Z0Tng__>)
The microservice architecture follows a scalable and distributed model, incorporating the following layers:

1. **Load Balancer:** Distributes requests among microservice instances to ensure high availability.
2. **API Layer (Go):** Responsible for validation and processing of requests.
3. **Cache Layer (Redis):** Speeds up queries by reducing database access.
4. **Database Layer (MongoDB with Sharding and Replica Sets):** Ensures high availability and fault tolerance. Since the system will initially have only two endpoints (POST and GET), database contention and lock-in issues are not a concern. Sharding is not required at this stage, simplifying database operations

### Data Flow

### POST

![Post.png](<https://media-hosting.imagekit.io/bfe80ba37bfd42e0/Post.png?Expires=1838379971&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=eWeaI1NfQhD~88T6ugzbNnEpIutIirCe7XP70HB8rPQ84ENeYacwwbRzL70J0ehWUYw4iAu3A-MLsyJJocD6stIcZV~8SGOvxsG2Wztl1aRGJ2nPk~iRIxo8vBwVFBklBT240Nz56CmQcpVF81oGnGZYooNFDs9XGOILojd~A0GJKPN8vt~xW-~uz2JmlRtcWTgQjSSOx-Zot0t9VDsr15C3WlQYR4uYdGVdr4bEZsE5Y3jD0bHEqr12Q1tdik2I4nwwA9CBw3nmwUYF1VCAcpdrUPCNEcBEp0lnzc2wx51Jk1JH9vzwG2jzNCAymdSiNeUFQneAWRnxxuF52MClDQ__>)
### GET

![Get.png](<https://media-hosting.imagekit.io/78ed0a218e384d16/Get.png?Expires=1838379972&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=e5HrpHME80v6sNsfkwzWDMXPRKooK9vaCc2BTPEP-iqFotQQuj7WbdumEFDPhCyjuUV29lB3Yj--YhQXTnNQiTzQQ13URyiWxZnsDTkh7aMRGXz3XPmAcocKyFTy3nUrT8nH-M0c4my5CAEewWjSoJZ69WE8KvGX-PNoQUM0mztP-5rOm1lTqj~6-DsdwaeQ9k6xFRcm8PRqwMtCaNT0c8B9yb2oqlMN9eSQBgRqFu7gkJwcFPV9RGHl0E2aQuILzRksapCsIBPKT-2FiofUKmdM2coUR7cXb651TgZn4bk~SuzmUX2kiCCQbvKk5Q0GxpMhkSqTrDBCLqn9DUIIHA__>)
### Containerization

The application will be containerized using Docker to ensure portability and ease of deployment.

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

This Dockerfile uses multi-stage build to create a small and secure final image. In the first stage, it uses a base Go image to compile the application with all necessary dependencies. In the second stage, it starts with a minimal image from scratch and copies only the compiled binary, resulting in a lightweight container with no extra tools or dependencies. This minimal setup helps reduce startup time and memory usage, which are essential to achieving the performance goal of keeping API responses consistently under 500ms.

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

This Docker Compose file defines a local development environment with three services: the main Go application (app), a Redis instance (redis), and a MongoDB instance (mongodb). It simplifies local testing by creating all necessary dependencies with a single command. While this setup is ideal for local development and testing, in a production environment, Redis and MongoDB would typically be managed separately, using dedicated infrastructure or managed services to ensure scalability, availability, and security.

## Deployment with Kubernetes

The application will be deployed in a Kubernetes cluster using the following configurations:

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
      app: microservice
  template:
    metadata:
      labels:
        app: microservice
    spec:
      containers:
        - name: app
          image: ${{ secrets.DOCKER_HUB_USER }}/ab-inbev-go:latest
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

To scale our application, we will be using **Horizontal Pod Autoscaler (HPA)**. Initially, to ensure performance and availability, the application will run with a **minimum of 3 pods**. The HPA can scale up to a **maximum of 10 pods**, based on resource usage. It constantly monitors the average CPU usage, and if it goes **above 80%**, new pods will be automatically added to handle the increased load. This ensures that our service can efficiently adapt to different levels of demand while maintaining responsiveness.

## CI/CD with GitHub Actions

The CI/CD pipeline automates testing, building, and deployment.

### Workflow YAML

![GitHub Actions.png](<https://media-hosting.imagekit.io/866dca1fe3cd4978/GitHub%20Actions.png?Expires=1838380016&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=CbgTC6m1MJOiiZcofkaKKAUoda7QJ4r2NKcKkVa3Q1KjEl8xIPR6NCRG2r79W6DBK-jhcEw0gwnc7FP7KpiA58WbXxTJB1N7LjhGiEsccJ7q6jpxZvrRWncEi7R3BM4-Nk~3kunkvcVulmfSX4X-KIY7NeBGvRP3dhhvZHus6PxEKKAWq~PCSxtocgYPMRAVlGqDs202KwxaIxDIue-sZq3GzmdWO0XSN9DxnTKbjJ4LDjisc13BJo1Q7wPxT0hlNcQBMCX0f7VAPAFmvYCFkNrp39WI0wxzM-rQpneYiWmkJrMyppHdtcB~Xm7Dt0lkUNnQwQWtwGgF8WILzgehTw__>)

```yaml
name: ab-inbev-ci-cd-go-workflow

on:
  push:
    branches:
      - main

jobs:
  ci:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-go@v2
        with:
          go-version: 1.15
      - run: go test
      - run: go run main.go
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v1
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1
      - name: Login to DockerHub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - name: Build and push
        id: docker_build
        uses: docker/build-push-action@v2
        with:
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/ab-inbev-go:latest

  cd:
    runs-on: ubuntu-latest
    needs: ci  # Garante que o deploy só roda depois do build
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Set up Kubectl
        uses: azure/k8s-set-context@v1
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}
      - name: Deploy
        run: |
          kubectl apply -f kubernetes/deployment.yaml
          kubectl apply -f kubernetes/service.yaml
          kubectl apply -f kubernetes/hpa.yaml
```

Our CI/CD pipeline is divided into two main stages. In the first stage (CI), we set up the environment, run automated tests, and then build and push the Docker image to a Docker registry. This ensures that each commit to the main branch results in a new, tested container image available for deployment.

In the second stage (CD), we use a Kubernetes configuration file (kubeconfig) that is securely stored in our secrets, allowing us to connect to the target cluster. After that, we apply the Kubernetes YAML files we defined earlier to deploy or update the application.

## Testing Strategy

We adopt a testing strategy based on the Test Pyramid, focusing primarily on unit tests to validate core functionalities such as input validation and data persistence. The goal is to ensure that all critical paths are covered, maintaining reliability and confidence in the application logic. While the current version prioritizes unit testing due to the simplicity of the codebase, the strategy also has space for future implementation of integration tests.

To validate performance goals, we plan to use tools like K6 to simulate concurrent users and ensure the application maintains response times under 500ms, as expected.

In addition, **observability** will play a key role in our strategy. By integrating tools such as **Prometheus** and **Grafana**, we can monitor application metrics in real-time and configure **alerts** to notify us of critical issues like high CPU usage or abnormal response times—helping us maintain system health and react quickly to incidents

## Trade-Offs and Future Considerations

The current architecture adopts a simple and efficient approach, combining load balancing, a Go API, Redis caching and a MongoDB database. This structure ensures high availability, low latency and operational simplicity, making it ideal for the current application requirements.

In the future, as the volume of requests grows, it will be important to consider alternatives to maintain scalability and performance. Since the POST endpoint needs to immediately return the generated ID to the client, the use of full asynchronous processing would not be appropriate, as it would compromise this functionality. However, it is possible to evaluate hybrid strategies, such as moving only less critical parts of the flow to a queue, while maintaining the synchronous return of the ID.

Another possible evolution is the adoption of serverless environments for the API, which could offer greater elasticity and cost optimization. Even so, it is essential to consider cold start as a possible latency point — especially if the application needs to maintain response time below 500ms.v# **Microservice Design Documentation**
