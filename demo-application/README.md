# Demo Application (Order Management System)

A simple, cloud-native Order Management System built as a technical assignment to demonstrate DevOps deployment readiness.

## Architecture

This application consists of two decoupled components and a database:
- **Frontend**: React + Vite (Served via Nginx)
- **Backend**: Python 3.12 + FastAPI + SQLAlchemy 2.0 (Served via Uvicorn)
- **Database**: PostgreSQL

The application is entirely stateless.

## Secrets Management Model

The application strictly consumes configuration via environment variables and **never** directly accesses AWS APIs for credentials.

For production deployment on EKS, secrets flow as follows:
```
AWS Secrets Manager -> External Secrets Operator -> Kubernetes Secret -> Application Pod Environment Variables
```

## Local Development (Docker Compose)

To run the full stack locally:
```bash
cp .env.example .env
docker compose up --build
```
- Frontend will be available at: http://localhost:3000
- Backend API will be available at: http://localhost:8000
- API Documentation at: http://localhost:8000/docs

## API Endpoints

- `GET /health` : Application liveness check
- `GET /ready` : Database connectivity check
- `GET /metrics` : Prometheus metrics
- `GET /api/v1/dashboard` : Stats overview
- `GET /api/v1/orders` : List orders
- `POST /api/v1/orders` : Create order
- `GET /api/v1/orders/{id}` : Get order
- `PATCH /api/v1/orders/{id}/status` : Update status
- `DELETE /api/v1/orders/{id}` : Delete order

## Testing
Backend tests can be run locally using Pytest (SQLite is used in-memory for testing):
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
pytest
```

## Deployment Assumptions

1. **Docker Hub**: Jenkins builds and pushes immutable image tags (e.g., `<git-sha>`) to Docker Hub.
2. **Kubernetes (EKS)**: The application depends on standard `Deployments` and `Services`.
3. **Database (RDS)**: EKS pods will communicate over the private network to RDS PostgreSQL.
4. **Prometheus**: Prometheus scrapes the `/metrics` endpoint on the backend service.
5. **Logging**: All logs are emitted to `stdout/stderr` and aggregated natively by Kubernetes.
