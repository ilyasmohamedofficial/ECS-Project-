FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

EXPOSE 80

# Run FastAPI using Uvicorn web server on port 80
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]