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


mkdir -p /home/ubuntu/monitoring
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
        environment:
            - GF_SECURITY_ADMIN_USER=admin
            - GF_SECURITY_ADMIN_PASSWORD=admin
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

# Raise the monitoring stack automatically
cd /home/ubuntu/monitoring && docker compose up -d