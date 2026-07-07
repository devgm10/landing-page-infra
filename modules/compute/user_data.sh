#!/bin/bash
set -e

# Instalación de Docker
apt-get update
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Create the app's docker-compose.yml
mkdir -p /home/ubuntu/landing
cat > /home/ubuntu/landing/docker-compose.yml << 'EOF'
services:
    web:
        image: devgm1995/landing-page:latest
        container_name: landing
        ports:
            - "80:80"
        restart: unless-stopped
EOF

chown -R ubuntu:ubuntu /home/ubuntu/landing

# Monitoring stack (Prometheus + Grafana + exporters)
mkdir -p /home/ubuntu/monitoring/grafana/provisioning/datasources
mkdir -p /home/ubuntu/monitoring/grafana/provisioning/dashboards
mkdir -p /home/ubuntu/monitoring/grafana/dashboards

# Configuración de Prometheus
printf 'global:\n  scrape_interval: 15s\n\nscrape_configs:\n  - job_name: "prometheus"\n    static_configs:\n      - targets: ["localhost:9090"]\n\n  - job_name: "node-exporter"\n    static_configs:\n      - targets: ["node-exporter:9100"]\n\n  - job_name: "cadvisor"\n    static_configs:\n      - targets: ["cadvisor:8080"]\n' > /home/ubuntu/monitoring/prometheus.yml

# Prometheus datasource provisioning
printf 'apiVersion: 1\n\ndatasources:\n  - name: Prometheus\n    type: prometheus\n    access: proxy\n    url: http://prometheus:9090\n    isDefault: true\n    editable: true\n' > /home/ubuntu/monitoring/grafana/provisioning/datasources/prometheus.yml

# Dashboard provisioning (tells Grafana where to look for them)
printf 'apiVersion: 1\n\nproviders:\n  - name: "default"\n    orgId: 1\n    folder: ""\n    type: file\n    disableDeletion: false\n    editable: true\n    options:\n      path: /var/lib/grafana/dashboards\n' > /home/ubuntu/monitoring/grafana/provisioning/dashboards/dashboards.yml

# Download the JSON dashboards from grafana.com
curl -sL https://grafana.com/api/dashboards/1860/revisions/latest/download -o /home/ubuntu/monitoring/grafana/dashboards/node-exporter.json
curl -sL https://grafana.com/api/dashboards/19792/revisions/latest/download -o /home/ubuntu/monitoring/grafana/dashboards/cadvisor.json

# Docker Compose monitoring stack
printf 'services:\n  prometheus:\n    image: prom/prometheus:latest\n    container_name: prometheus\n    ports:\n      - "9090:9090"\n    volumes:\n      - ./prometheus.yml:/etc/prometheus/prometheus.yml\n      - prometheus_data:/prometheus\n    restart: unless-stopped\n\n  grafana:\n    image: grafana/grafana:latest\n    container_name: grafana\n    ports:\n      - "3000:3000"\n    volumes:\n      - grafana_data:/var/lib/grafana\n      - ./grafana/provisioning:/etc/grafana/provisioning\n      - ./grafana/dashboards:/var/lib/grafana/dashboards\n    restart: unless-stopped\n\n  node-exporter:\n    image: prom/node-exporter:latest\n    container_name: node-exporter\n    ports:\n      - "9100:9100"\n    restart: unless-stopped\n\n  cadvisor:\n    image: gcr.io/cadvisor/cadvisor:latest\n    container_name: cadvisor\n    ports:\n      - "8080:8080"\n    volumes:\n      - /:/rootfs:ro\n      - /var/run:/var/run:ro\n      - /sys:/sys:ro\n      - /var/lib/docker/:/var/lib/docker:ro\n    restart: unless-stopped\n\nvolumes:\n  prometheus_data:\n  grafana_data:\n' > /home/ubuntu/monitoring/docker-compose.yml

chown -R ubuntu:ubuntu /home/ubuntu/monitoring

# Levantar el stack de monitoreo
cd /home/ubuntu/monitoring && docker compose up -d