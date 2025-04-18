# Endpoint Statistics Application Runbook

This runbook provides comprehensive step-by-step instructions for deploying, testing, and managing the Endpoint Statistics application Kubernetes infrastructure. Follow these instructions to set up, validate, and maintain the application environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [1. Deploying the Cluster](#1-deploying-the-cluster)
- [2. Testing Components](#2-testing-components)
- [3. Deployment Strategies](#3-deployment-strategies)
- [4. Cleanup Procedures](#4-cleanup-procedures)
- [5. Troubleshooting](#5-troubleshooting)

## Prerequisites

Before proceeding, ensure you have the following tools and configurations in place:

- Kubernetes cluster (Minikube, Kind, or Docker Desktop Kubernetes)
- `kubectl` command-line tool installed and configured
- Docker installed for building and pushing images
- Git repository cloned locally

### Environment Setup

```bash
# Verify kubectl installation
kubectl version --client

# Verify Kubernetes cluster is running
kubectl cluster-info

# Ensure context is set correctly
kubectl config current-context
```

## 1. Deploying the Cluster

Follow these steps to deploy the complete Kubernetes infrastructure for the Endpoint Statistics application.

### 1.1 Create the Namespace

```bash
# Create a dedicated namespace for the application
kubectl apply -f k8s/core/namespace.yaml

# Verify the namespace was created
kubectl get namespaces | grep endpoint-stats
```

### 1.2 Deploy Storage Resources

```bash
# Create persistent volumes and claims
kubectl apply -f k8s/storage/persistent-volumes.yaml

# Verify persistent volumes and claims are created
kubectl get pv
kubectl get pvc -n endpoint-stats
```

### 1.3 Deploy Secrets

```bash
# Create Kubernetes secrets for sensitive information
kubectl apply -f k8s/security/secrets.yaml

# Verify secrets are created (no values will be displayed)
kubectl get secrets -n endpoint-stats
```

### 1.4 Deploy Database

```bash
# Deploy PostgreSQL database
kubectl apply -f k8s/database/postgres.yaml

# Verify PostgreSQL pods are running
kubectl get pods -n endpoint-stats -l app=postgres
kubectl get svc -n endpoint-stats -l app=postgres

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n endpoint-stats --timeout=180s
```

### 1.5 Deploy Redis Cache

```bash
# Deploy Redis for caching
kubectl apply -f k8s/cache/redis.yaml

# Verify Redis pods are running
kubectl get pods -n endpoint-stats -l app=redis
kubectl get svc -n endpoint-stats -l app=redis

# Wait for Redis to be ready
kubectl wait --for=condition=ready pod -l app=redis -n endpoint-stats --timeout=120s
```

### 1.6 Deploy Flask API

```bash
# Deploy the Flask API application
kubectl apply -f k8s/core/flask-api.yaml

# Verify Flask API pods are running
kubectl get pods -n endpoint-stats -l app=flask-api
kubectl get svc -n endpoint-stats -l app=flask-api

# Wait for Flask API to be ready
kubectl wait --for=condition=ready pod -l app=flask-api -n endpoint-stats --timeout=120s
```

### 1.7 Configure Ingress

```bash
# Deploy ingress rules
kubectl apply -f k8s/networking/ingress.yaml

# Verify ingress is configured
kubectl get ingress -n endpoint-stats
```

### 1.8 Deploy Monitoring Stack

```bash
# Deploy Prometheus, Grafana, and related components
kubectl apply -f k8s/monitoring/

# Verify monitoring components are running
kubectl get pods -n endpoint-stats -l app=prometheus
kubectl get pods -n endpoint-stats -l app=grafana
kubectl get pods -n endpoint-stats -l app=alertmanager

# Wait for monitoring components to be ready
kubectl wait --for=condition=ready pod -l app=prometheus -n endpoint-stats --timeout=180s
kubectl wait --for=condition=ready pod -l app=grafana -n endpoint-stats --timeout=180s
```

### 1.9 Configure Monitoring Dashboards

```bash
# Run the dashboard checker script to set up dashboards in Grafana
python scripts/monitoring/dashboard-checker.py

# Verify dashboards exist in Grafana
# Access Grafana UI (port-forward if needed)
kubectl port-forward -n endpoint-stats svc/grafana 3000:3000
# Then open http://localhost:3000 in your browser (default credentials: admin/admin)
```

### 1.10 Access the Application

```bash
# Set up port forwarding to access the application
kubectl port-forward -n endpoint-stats svc/flask-api 9999:9999

# In a web browser, navigate to http://localhost:9999
# You should see the welcome message and access count
```

## 2. Testing Components

Follow these steps to verify that each component is working as expected.

### 2.1 Run Health Check Script

```bash
# Execute the health check script
./scripts/health-check.sh test-health-report.txt

# Review the health report
cat test-health-report.txt
```

### 2.2 Test Flask API

```bash
# Access the root endpoint (should return welcome message and access count)
curl http://localhost:9999/

# Access the stats endpoint (should return access statistics)
curl http://localhost:9999/stats
```

### 2.3 Test Database Connectivity

```bash
# Get the PostgreSQL pod name
POSTGRES_POD=$(kubectl get pods -n endpoint-stats -l app=postgres -o name | head -1)

# Test database connection and query data
kubectl exec -n endpoint-stats ${POSTGRES_POD} -- bash -c "export PGPASSWORD=\$(cat /etc/postgres-secret/password); psql -U admin -d endpoint_stats -c 'SELECT * FROM endpoints LIMIT 5;'"
```

### 2.4 Test Redis Connectivity

```bash
# Get the Redis pod name
REDIS_POD=$(kubectl get pods -n endpoint-stats -l app=redis -o name | head -1)

# Test Redis connection and check cached keys
kubectl exec -n endpoint-stats ${REDIS_POD} -- redis-cli PING
kubectl exec -n endpoint-stats ${REDIS_POD} -- redis-cli KEYS "*"
```

### 2.5 Test Prometheus Metrics

```bash
# Set up port forwarding to access Prometheus
kubectl port-forward -n endpoint-stats svc/prometheus 9090:9090

# Access Prometheus in a web browser: http://localhost:9090
# Check the status of targets and explore metrics
```

### 2.6 Test Grafana Dashboards

```bash
# Set up port forwarding to access Grafana
kubectl port-forward -n endpoint-stats svc/grafana 3000:3000

# Access Grafana in a web browser: http://localhost:3000
# Default credentials: admin/admin
# Verify dashboards are loading and displaying metrics
```

## 3. Deployment Strategies

This section covers testing deployment strategies like rollback and disaster recovery.

### 3.1 Testing Rollback Procedure

```bash
# Deploy a new version of the application
./scripts/deployment/deploy.sh v2 endpoint-stats flask-api

# Verify the new version is deployed
kubectl get pods -n endpoint-stats -l app=flask-api

# Perform rollback to previous version
./scripts/deployment/rollback.sh flask-api endpoint-stats

# Verify rollback was successful
kubectl get pods -n endpoint-stats -l app=flask-api
kubectl rollout history deployment/flask-api -n endpoint-stats
```

### 3.2 Testing Disaster Recovery

```bash
# Simulate a database backup (normally scheduled)
POSTGRES_POD=$(kubectl get pods -n endpoint-stats -l app=postgres -o name | head -1)
kubectl exec -n endpoint-stats ${POSTGRES_POD} -- bash -c "export PGPASSWORD=\$(cat /etc/postgres-secret/password); pg_dump -U admin endpoint_stats > /tmp/backup-$(date +%Y%m%d).sql"
kubectl cp endpoint-stats/${POSTGRES_POD#*/}:/tmp/backup-$(date +%Y%m%d).sql ./backup-$(date +%Y%m%d).sql

# Simulate a disaster (for testing purposes)
kubectl delete pod -n endpoint-stats -l app=postgres

# Wait for the database to recover automatically
kubectl wait --for=condition=ready pod -l app=postgres -n endpoint-stats --timeout=180s

# If needed, restore from backup
./scripts/backup/dr-restore.sh ./backup-$(date +%Y%m%d).sql

# Verify database restoration
POSTGRES_POD=$(kubectl get pods -n endpoint-stats -l app=postgres -o name | head -1)
kubectl exec -n endpoint-stats ${POSTGRES_POD} -- bash -c "export PGPASSWORD=\$(cat /etc/postgres-secret/password); psql -U admin -d endpoint_stats -c 'SELECT count(*) FROM endpoints;'"
```

## 4. Cleanup Procedures

Follow these steps to clean up all deployed resources after completion.

### 4.1 Delete Application Components

```bash
# Remove Flask API deployment
kubectl delete -f k8s/core/flask-api.yaml

# Remove Redis cache
kubectl delete -f k8s/cache/redis.yaml

# Remove PostgreSQL database
kubectl delete -f k8s/database/postgres.yaml
```

### 4.2 Delete Monitoring Stack

```bash
# Remove monitoring components
kubectl delete -f k8s/monitoring/
```

### 4.3 Delete Ingress and Configuration

```bash
# Remove ingress rules
kubectl delete -f k8s/networking/ingress.yaml

# Remove secrets
kubectl delete -f k8s/security/secrets.yaml
```

### 4.4 Delete Storage Resources

```bash
# First verify no pods are using the volumes
kubectl get pods -n endpoint-stats

# Delete persistent volume claims
kubectl delete pvc -n endpoint-stats --all

# Delete persistent volumes
kubectl delete -f k8s/storage/persistent-volumes.yaml
```

### 4.5 Delete Namespace

```bash
# Delete the entire namespace (this will delete all resources in the namespace)
kubectl delete -f k8s/core/namespace.yaml

# Verify namespace is removed
kubectl get namespaces | grep endpoint-stats
```

## 5. Troubleshooting

This section provides guidance for resolving common issues that may arise.

### 5.1 Pod Startup Issues

If pods fail to start:

```bash
# Check pod status
kubectl get pods -n endpoint-stats

# Describe the problematic pod
kubectl describe pod <pod-name> -n endpoint-stats

# Check pod logs
kubectl logs <pod-name> -n endpoint-stats

# Check recent events
kubectl get events -n endpoint-stats --sort-by='.lastTimestamp'
```

### 5.2 Database Connection Issues

If applications cannot connect to PostgreSQL:

```bash
# Verify PostgreSQL pod is running
kubectl get pods -n endpoint-stats -l app=postgres

# Check PostgreSQL logs
POSTGRES_POD=$(kubectl get pods -n endpoint-stats -l app=postgres -o name | head -1)
kubectl logs -n endpoint-stats ${POSTGRES_POD}

# Test database connection from within the cluster
kubectl exec -n endpoint-stats deployment/flask-api -- curl -s http://postgres:5432

# Verify secrets are properly mounted
kubectl describe pod ${POSTGRES_POD} -n endpoint-stats | grep -A5 Mounts:
```

### 5.3 Redis Connection Issues

If applications cannot connect to Redis:

```bash
# Verify Redis pod is running
kubectl get pods -n endpoint-stats -l app=redis

# Check Redis logs
REDIS_POD=$(kubectl get pods -n endpoint-stats -l app=redis -o name | head -1)
kubectl logs -n endpoint-stats ${REDIS_POD}

# Test Redis connection from within the cluster
kubectl exec -n endpoint-stats deployment/flask-api -- curl -s http://redis:6379
```

### 5.4 Monitoring Stack Issues

If Prometheus or Grafana is not working properly:

```bash
# Check Prometheus pod status
kubectl get pods -n endpoint-stats -l app=prometheus
kubectl logs -n endpoint-stats $(kubectl get pods -n endpoint-stats -l app=prometheus -o name | head -1)

# Check Grafana pod status
kubectl get pods -n endpoint-stats -l app=grafana
kubectl logs -n endpoint-stats $(kubectl get pods -n endpoint-stats -l app=grafana -o name | head -1)

# Verify ConfigMaps are correctly created
kubectl get configmaps -n endpoint-stats

# Verify persistent volumes are correctly bound
kubectl get pvc -n endpoint-stats
```

### 5.5 Resource Constraints

If pods are being terminated due to resource constraints:

```bash
# Check node resources
kubectl describe nodes

# Check pod resource usage
kubectl top pods -n endpoint-stats

# Adjust resource limits in deployment files if necessary
# Then reapply the modified configuration
kubectl apply -f <modified-file>
```

### 5.6 Service Discovery Issues

If services cannot find each other:

```bash
# Verify service endpoints
kubectl get endpoints -n endpoint-stats

# Check DNS resolution from a pod
kubectl exec -n endpoint-stats deployment/flask-api -- nslookup postgres
kubectl exec -n endpoint-stats deployment/flask-api -- nslookup redis

# Test connectivity between services
kubectl exec -n endpoint-stats deployment/flask-api -- curl -s http://postgres:5432
kubectl exec -n endpoint-stats deployment/flask-api -- curl -s http://redis:6379
```

### 5.7 Ingress Issues

If ingress is not properly routing traffic:

```bash
# Check ingress status
kubectl get ingress -n endpoint-stats
kubectl describe ingress -n endpoint-stats

# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### 5.8 General Diagnostic Commands

Useful commands for diagnosing various issues:

```bash
# Run comprehensive health check
./scripts/health-check.sh detailed-report.txt

# Check all resources in the namespace
kubectl get all -n endpoint-stats

# Check storage status
kubectl get pv,pvc -n endpoint-stats

# Check ConfigMaps and Secrets (without revealing values)
kubectl get configmaps,secrets -n endpoint-stats

# Check network policies
kubectl get networkpolicies -n endpoint-stats
```

This runbook should be kept up-to-date as the infrastructure evolves. For questions or issues not covered here, consult the project documentation or reach out to the DevOps team.
