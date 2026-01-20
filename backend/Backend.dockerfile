FROM python:3.11-slim

# Set work directory
WORKDIR /app

# Install Python dependencies first (better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user to run the app
RUN useradd -m appuser
USER appuser


# Copy application code
COPY . .

# stdout/stderr unbuffered
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

#start the app 
CMD ["python", "app.py"]
