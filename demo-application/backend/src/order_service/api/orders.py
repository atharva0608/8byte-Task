from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
import logging

from order_service import schemas, models
from order_service.database import get_db
from order_service.services import order_service as svc
from order_service.metrics import ORDERS_CREATED, ORDERS_UPDATED, ORDERS_DELETED

router = APIRouter()
logger = logging.getLogger(__name__)

# Valid transitions
VALID_TRANSITIONS = {
    models.OrderStatus.PLACED: [models.OrderStatus.PROCESSING, models.OrderStatus.CANCELLED],
    models.OrderStatus.PROCESSING: [models.OrderStatus.SHIPPED, models.OrderStatus.CANCELLED],
    models.OrderStatus.SHIPPED: [models.OrderStatus.DELIVERED],
    models.OrderStatus.DELIVERED: [],
    models.OrderStatus.CANCELLED: []
}

@router.post("/", response_model=schemas.OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(order: schemas.OrderCreate, db: Session = Depends(get_db)):
    try:
        db_order = svc.create_order(db, order)
        ORDERS_CREATED.inc()
        logger.info(f"Order {db_order.id} created successfully.")
        
        # Calculate total property for response explicitly since it's an API requirement
        total = db_order.quantity * db_order.unit_price
        response = schemas.OrderResponse.model_validate(db_order)
        response.total = total
        return response
    except Exception as e:
        logger.error(f"Failed to create order: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/", response_model=List[schemas.OrderResponse])
def list_orders(skip: int = 0, limit: int = 100, status: Optional[models.OrderStatus] = None, db: Session = Depends(get_db)):
    orders = svc.get_orders(db, skip=skip, limit=limit, status=status)
    responses = []
    for o in orders:
        resp = schemas.OrderResponse.model_validate(o)
        resp.total = o.quantity * o.unit_price
        responses.append(resp)
    return responses

@router.get("/{order_id}", response_model=schemas.OrderResponse)
def get_order(order_id: int, db: Session = Depends(get_db)):
    db_order = svc.get_order(db, order_id)
    if db_order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    
    response = schemas.OrderResponse.model_validate(db_order)
    response.total = db_order.quantity * db_order.unit_price
    return response

@router.patch("/{order_id}/status", response_model=schemas.OrderResponse)
def update_order_status(order_id: int, status_update: schemas.OrderStatusUpdate, db: Session = Depends(get_db)):
    db_order = svc.get_order(db, order_id)
    if db_order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    if status_update.status not in VALID_TRANSITIONS[db_order.status] and status_update.status != db_order.status:
        logger.warning(f"Invalid transition attempted for order {order_id}: {db_order.status} -> {status_update.status}")
        raise HTTPException(status_code=400, detail=f"Invalid status transition from {db_order.status} to {status_update.status}")

    updated_order = svc.update_order_status(db, order_id, status_update.status)
    ORDERS_UPDATED.labels(status=status_update.status.value).inc()
    logger.info(f"Order {order_id} status updated to {status_update.status.value}")
    
    response = schemas.OrderResponse.model_validate(updated_order)
    response.total = updated_order.quantity * updated_order.unit_price
    return response

@router.delete("/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_order(order_id: int, db: Session = Depends(get_db)):
    success = svc.delete_order(db, order_id)
    if not success:
        raise HTTPException(status_code=404, detail="Order not found")
    ORDERS_DELETED.inc()
    logger.info(f"Order {order_id} deleted successfully.")
    return None
