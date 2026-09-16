from pydantic import BaseModel, Field
from decimal import Decimal
from typing import Optional
from datetime import datetime
from order_service.models import OrderStatus

class OrderBase(BaseModel):
    customer_name: str = Field(..., min_length=1, max_length=100)
    product_name: str = Field(..., min_length=1, max_length=200)
    quantity: int = Field(..., gt=0)
    unit_price: Decimal = Field(..., gt=0)

class OrderCreate(OrderBase):
    pass

class OrderStatusUpdate(BaseModel):
    status: OrderStatus

class OrderResponse(OrderBase):
    id: int
    status: OrderStatus
    total: Decimal
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
