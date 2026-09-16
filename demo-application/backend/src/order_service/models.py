from sqlalchemy import Column, Integer, String, Numeric, DateTime, Enum as SQLEnum
from sqlalchemy.sql import func
import enum
from order_service.database import Base

class OrderStatus(str, enum.Enum):
    PLACED = "PLACED"
    PROCESSING = "PROCESSING"
    SHIPPED = "SHIPPED"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    customer_name = Column(String(100), nullable=False)
    product_name = Column(String(200), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)
    status = Column(SQLEnum(OrderStatus), default=OrderStatus.PLACED, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    @property
    def total(self):
        return self.quantity * self.unit_price
