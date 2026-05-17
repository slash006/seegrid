FROM python:3.10-slim-bullseye
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libx11-6 \
    libxrender1 \
    libxext6 \
    binutils \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN pip install --no-cache-dir opencv-python numpy pyinstaller
COPY . .
CMD ["pyinstaller", "--onefile", "--clean", "main.py"]
