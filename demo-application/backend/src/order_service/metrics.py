from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Request, Response
from typing import Callable
import time

# Prometheus Metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP Requests",
    ["method", "route", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP Request Latency",
    ["method", "route"]
)

ERROR_COUNT = Counter(
    "http_errors_total",
    "Total HTTP Errors",
    ["method", "route"]
)

# Business Metrics
ORDERS_CREATED = Counter("orders_created_total", "Total orders created")
ORDERS_UPDATED = Counter("orders_status_updates_total", "Total order status updates", ["status"])
ORDERS_DELETED = Counter("orders_deleted_total", "Total orders deleted")

def metrics_endpoint() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
