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
cat > /home/ubuntu/monitoring/docker-compose.yml << 'DOCKEREOF'
services:
    prometheus:
        image: prom/prometheus:latest
        container_name: prometheus
        ports:
            - "9090:9090"
        volumes:
            - ./prometheus.yml:/etc/prometheus/prometheus.yml
            - prometheus_data:/prometheus
        restart: unless-stopped

    grafana:
        image: grafana/grafana:latest
        container_name: grafana
        ports:
            - "3000:3000"
        volumes:
            - grafana_data:/var/lib/grafana
            - ./grafana/provisioning:/etc/grafana/provisioning
            - ./grafana/dashboards:/var/lib/grafana/dashboards
        restart: unless-stopped

    node-exporter:
        image: prom/node-exporter:latest
        container_name: node-exporter
        ports:
            - "9100:9100"
        restart: unless-stopped

    cadvisor:
        image: gcr.io/cadvisor/cadvisor:latest
        container_name: cadvisor
        ports:
            - "8080:8080"
        volumes:
            - /:/rootfs:ro
            - /var/run:/var/run:ro
            - /sys:/sys:ro
            - /var/lib/docker/:/var/lib/docker:ro
        restart: unless-stopped

volumes:
    prometheus_data:
    grafana_data:
DOCKEREOF

chown -R ubuntu:ubuntu /home/ubuntu/monitoring

# Levantar el stack de monitoreo
cd /home/ubuntu/monitoring && docker compose up -d