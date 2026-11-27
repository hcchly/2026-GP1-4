FROM python:3.11-slim
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 KHOTA_DEVICE=cpu YOLO_CONFIG_DIR=/tmp/Ultralytics
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install torch==2.6.0 torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cpu && pip install -r requirements.txt
COPY khota ./khota
COPY weights ./weights
CMD exec python -m uvicorn khota.api:app --host 0.0.0.0 --port ${PORT:-8080}
