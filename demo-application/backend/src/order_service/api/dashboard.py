from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Dict, Any

from order_service.database import get_db
from order_service.services import order_service as svc
from order_service import schemas

router = APIRouter()

@router.get("/")
def get_dashboard(db: Session = Depends(get_db)):
    stats = svc.get_dashboard_stats(db)
    
    # Format recent orders
    recent_responses = []
    for o in stats["recent_orders"]:
        resp = schemas.OrderResponse.model_validate(o)
        resp.total = o.quantity * o.unit_price
        recent_responses.append(resp)
        
    stats["recent_orders"] = recent_responses
    return stats
