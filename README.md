# High Performance Microservice

This project presents a high-performance microservice architecture designed to be fast, scalable, and easy to maintain.

## 1. Overview

The microservice exposes two endpoints:

- `POST /resource`: Creates a new resource.
- `GET /resource/:id`: Retrieves a resource by ID.

### Key Technologies

- **Go**
- **MongoDB**
- **Redis**
- **Docker**
- **Kubernetes**

## 2. Setup

### Local Development

Make sure you have Docker and Docker Compose installed.

```bash
docker-compose up --build
```

### Kubernetes Deployment

Apply the manifests in the `k8s/` folder:

```bash
kubectl apply -f k8s/
```

## 3. Technical Decisions

- **Go** was selected for its performance and low memory usage, which helps meet the 500ms response time goal.
- **MongoDB**  was chosen for its document model. As we’re storing and retrieving JSON, it fits perfectly.
- With only two endpoints, we minimize locking and complexity at the database level.
- **Redis** improves performance by caching frequent reads.
- We’ve chosen to start simple and scale features (like sharding) only when needed.

## 4. CI/CD

The project uses GitHub Actions for:

- Building and testing the application.
- Deploying to Kubernetes clusters.

---
