from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from order_service.database import get_db
from order_service.metrics import metrics_endpoint
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/health", status_code=status.HTTP_200_OK)
def health_check():
    # Process is alive
    return {"status": "ok"}

@router.get("/ready", status_code=status.HTTP_200_OK)
def readiness_check(db: Session = Depends(get_db)):
    try:
        # Check database connectivity
        db.execute(text("SELECT 1"))
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service unavailable. Database disconnected."
        )

@router.get("/metrics")
def get_metrics():
    return metrics_endpoint()
