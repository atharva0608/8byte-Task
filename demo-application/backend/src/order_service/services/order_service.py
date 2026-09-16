from sqlalchemy.orm import Session
from sqlalchemy import func
from order_service import models, schemas
from typing import List, Optional

def create_order(db: Session, order: schemas.OrderCreate) -> models.Order:
    db_order = models.Order(**order.model_dump())
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order

def get_orders(db: Session, skip: int = 0, limit: int = 100, status: Optional[models.OrderStatus] = None) -> List[models.Order]:
    query = db.query(models.Order)
    if status:
        query = query.filter(models.Order.status == status)
    return query.order_by(models.Order.created_at.desc()).offset(skip).limit(limit).all()

def get_order(db: Session, order_id: int) -> Optional[models.Order]:
    return db.query(models.Order).filter(models.Order.id == order_id).first()

def update_order_status(db: Session, order_id: int, status: models.OrderStatus) -> Optional[models.Order]:
    db_order = get_order(db, order_id)
    if db_order:
        db_order.status = status
        db.commit()
        db.refresh(db_order)
    return db_order

def delete_order(db: Session, order_id: int) -> bool:
    db_order = get_order(db, order_id)
    if db_order:
        db.delete(db_order)
        db.commit()
        return True
    return False

def get_dashboard_stats(db: Session) -> dict:
    total_orders = db.query(func.count(models.Order.id)).scalar()
    
    status_counts = db.query(models.Order.status, func.count(models.Order.id)).group_by(models.Order.status).all()
    stats = {status.value: 0 for status in models.OrderStatus}
    for status, count in status_counts:
        stats[status.value] = count

    recent_orders = db.query(models.Order).order_by(models.Order.created_at.desc()).limit(5).all()

    return {
        "total": total_orders,
        "by_status": stats,
        "recent_orders": recent_orders
    }
