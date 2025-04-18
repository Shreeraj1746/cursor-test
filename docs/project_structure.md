# Project Structure Documentation

This document provides an overview of the Endpoint Statistics application project structure, explaining the purpose of each directory and how the components fit together.

## Directory Structure

```
explore-k8s/
├── k8s/                       # Kubernetes configuration files
│   ├── cache/                 # Redis cache configurations
│   ├── core/                  # Core application components
│   ├── database/              # Database configurations
│   ├── deployment-strategy/   # Deployment strategies
│   ├── maintenance/           # Maintenance tasks and jobs
│   ├── monitoring/            # Monitoring stack configuration
│   ├── networking/            # Ingress and service configurations
│   ├── security/              # Security, RBAC, and network policies
│   └── storage/               # Persistent storage configurations
├── scripts/                   # Operational scripts
│   ├── backup/                # Backup and restore scripts
│   ├── deployment/            # Deployment and rollback scripts
│   ├── monitoring/            # Monitoring configuration scripts
│   └── health-check.sh        # Health check utility
├── docs/                      # Documentation
├── tests/                     # Test files
└── app.py                     # Main application file
```

## Kubernetes Directory (k8s/)

The `k8s/` directory contains all Kubernetes configuration files, organized into logical subdirectories:

### Core (k8s/core/)
Contains the core application components:
- `namespace.yaml`: Defines the Kubernetes namespace
- `flask-api.yaml`: Deployment and service for the Flask API application
- `flask-api-current.yaml`: Current active deployment configuration

### Cache (k8s/cache/)
Redis caching components:
- `redis.yaml`: Redis deployment and service

### Database (k8s/database/)
Database components:
- `postgres.yaml`: PostgreSQL deployment and service

### Deployment Strategy (k8s/deployment-strategy/)
Advanced deployment configurations:
- `flask-api-deployment.yaml`: Specialized deployment configuration
- `flask-api-hpa.yaml`: Horizontal Pod Autoscaler configuration

### Maintenance (k8s/maintenance/)
Maintenance-related configurations:
- `backup-job.yaml`: Database backup job
- `backup-pvc.yaml`: Persistent volume claim for backups
- `disaster-recovery-plan.yaml`: Disaster recovery procedures
- Other maintenance configurations

### Monitoring (k8s/monitoring/)
Monitoring stack configurations:
- Prometheus, Grafana, and Alertmanager configurations
- Exporters for PostgreSQL and Redis
- Service monitors and alerts
- Dashboard configurations

### Networking (k8s/networking/)
Network-related configurations:
- `ingress.yaml`: Ingress configuration
- `db-alias-service.yaml`: Database alias service

### Security (k8s/security/)
Security-related configurations:
- `secrets.yaml`: Application secrets
- Network policies for various components
- RBAC configurations
- TLS configurations

### Storage (k8s/storage/)
Storage-related configurations:
- `persistent-volumes.yaml`: Persistent volume definitions

## Scripts Directory (scripts/)

The `scripts/` directory contains operational scripts for managing, deploying, and monitoring the application:

### Backup (scripts/backup/)
Backup and restore scripts:
- `db-backup.sh`: Database backup script
- `dr-restore.sh`: Disaster recovery restore script

### Deployment (scripts/deployment/)
Deployment-related scripts:
- `deploy.sh`: Application deployment script
- `rollback.sh`: Deployment rollback script

### Monitoring (scripts/monitoring/)
Monitoring-related scripts:
- `dashboard-checker.py`: Grafana dashboard setup script

### Health Check (scripts/health-check.sh)
General-purpose health check utility script

## Application Code

- `app.py`: Main Flask application file
- `requirements.txt`: Python dependencies
- `Dockerfile`: Container image definition
- `docker-compose.yml`: Development environment configuration

## Tests

- `tests/`: Test files for the application
- `pytest.ini`: PyTest configuration
- `requirements-test.txt`: Testing dependencies

## Documentation

- `Runbook.md`: Step-by-step operational guide
- `README.md`: Project overview and getting started
- `docs/`: Additional documentation files

## How Components Interact

1. **Core Application Flow**:
   - Flask API receives requests
   - Data is stored in PostgreSQL
   - Redis is used for caching

2. **Kubernetes Resources Flow**:
   - Namespace contains all resources
   - Persistent volumes provide storage
   - Deployments manage application containers
   - Services expose components internally
   - Ingress exposes services externally

3. **Monitoring Flow**:
   - Prometheus collects metrics
   - Grafana visualizes metrics
   - Alertmanager handles alerts

4. **Operational Flow**:
   - Deployment scripts deploy new versions
   - Backup scripts create database backups
   - Health check script verifies system health

## Getting Started for New Developers

1. Run the setup script to set up your environment:
   ```bash
   ./scripts/setup.sh dev  # Development environment
   ./scripts/setup.sh k8s  # Kubernetes environment
   ./scripts/setup.sh all  # Both environments
   ```

2. Follow the Runbook for deploying and managing the application:
   ```bash
   # See Runbook.md for detailed instructions
   ```

3. Review the documentation in the `docs/` directory for specific aspects of the system.

4. Explore the Kubernetes configurations in the `k8s/` directory to understand the infrastructure.

This structure ensures a clean separation of concerns, making it easier to understand, maintain, and extend the application.
