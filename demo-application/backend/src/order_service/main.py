from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import time
import logging

from order_service.config import settings
from order_service.logging_config import setup_logging
from order_service.metrics import REQUEST_COUNT, REQUEST_LATENCY, ERROR_COUNT
from order_service.api import health, orders, dashboard

# Setup logging
setup_logging(settings.log_level)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting {settings.app_name} in {settings.app_env} mode.")
    yield
    logger.info(f"Shutting down {settings.app_name}.")

app = FastAPI(
    title=settings.app_name,
    description="Demo Application Order API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in settings.cors_origins.split(",")] if settings.cors_origins != "*" else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Metrics Middleware
@app.middleware("http")
async def add_metrics(request: Request, call_next):
    start_time = time.time()
    route_path = request.url.path
    method = request.method
    
    try:
        response = await call_next(request)
        status_code = str(response.status_code)
        if response.status_code >= 500:
            ERROR_COUNT.labels(method=method, route=route_path).inc()
    except Exception as e:
        status_code = "500"
        ERROR_COUNT.labels(method=method, route=route_path).inc()
        raise e
    finally:
        latency = time.time() - start_time
        REQUEST_COUNT.labels(method=method, route=route_path, status=status_code).inc()
        REQUEST_LATENCY.labels(method=method, route=route_path).observe(latency)
        
    return response

# Include Routers
app.include_router(health.router)
app.include_router(orders.router, prefix="/api/v1/orders", tags=["Orders"])
app.include_router(dashboard.router, prefix="/api/v1/dashboard", tags=["Dashboard"])
