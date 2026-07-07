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
mkdir -p /home/ubuntu/monitoring
mkdir -p /home/ubuntu/monitoring/grafana/provisioning/datasources
mkdir -p /home/ubuntu/monitoring/grafana/provisioning/dashboards
mkdir -p /home/ubuntu/monitoring/grafana/dashboards

# Prometheus Configuration
cat > /home/ubuntu/monitoring/prometheus.yml << 'EOF'
global:
    scrape_interval: 15s

scrape_configs:
    - job_name: 'prometheus'
        static_configs:
        - targets: ['localhost:9090']

    - job_name: 'node-exporter'
        static_configs:
        - targets: ['node-exporter:9100']

    - job_name: 'cadvisor'
        static_configs:
        - targets: ['cadvisor:8080']
EOF

# provisioning: Prometheus datasource (auto-connected)
cat > /home/ubuntu/monitoring/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
    - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
        isDefault: true
        editable: true
EOF

# Provisioning: config that tells Grafana where to look for dashboards
cat > /home/ubuntu/monitoring/grafana/provisioning/dashboards/dashboards.yml << 'EOF'
apiVersion: 1

providers:
    - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
            path: /var/lib/grafana/dashboards
EOF

# Download the JSON dashboards from grafana.com
curl -sL https://grafana.com/api/dashboards/1860/revisions/latest/download \
    -o /home/ubuntu/monitoring/grafana/dashboards/node-exporter.json
curl -sL https://grafana.com/api/dashboards/19792/revisions/latest/download \
    -o /home/ubuntu/monitoring/grafana/dashboards/cadvisor.json

# Docker Compose monitoring stack
cat > /home/ubuntu/monitoring/docker-compose.yml << 'EOF'
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
EOF

chown -R ubuntu:ubuntu /home/ubuntu/monitoring

# Raise the monitoring stack
cd /home/ubuntu/monitoring && docker compose up -d