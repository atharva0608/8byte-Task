FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# Copy application code
COPY src/ /app/src/
COPY alembic/ /app/alembic/
COPY alembic.ini /app/

# Expose port
EXPOSE 8000

# Start command
CMD ["uvicorn", "order_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
