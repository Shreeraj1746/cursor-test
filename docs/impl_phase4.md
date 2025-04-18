# Phase 4: Deployment Strategy

## Overview

This phase focuses on implementing deployment strategies and rolling updates for the Endpoint Statistics application. We'll set up deployment configurations, rolling updates, and scaling rules to ensure reliable and efficient deployments with minimal downtime. A well-designed deployment strategy ensures application reliability while enabling continuous delivery.

## Deployment Approaches

There are several approaches to deploying applications in Kubernetes, each with specific benefits:

1. **Rolling Updates** (default): Gradual replacement of old pods with new ones
   - Benefits: Zero downtime, gradual rollout, automatic rollback
   - Best for: Most applications with stateless components

2. **Blue-Green Deployments**: Maintain two identical environments (blue and green)
   - Benefits: Instant cutover, easy rollback, full testing in production environment
   - Best for: Applications requiring extensive pre-release validation

3. **Canary Deployments**: Release to a small subset of users first
   - Benefits: Early feedback, reduced risk, controlled exposure
   - Best for: User-facing applications with high-risk changes

4. **StatefulSet Deployments**: Ordered and unique deployments
   - Benefits: Stable network identifiers, persistent storage, ordered scaling
   - Best for: Stateful applications like databases

For the Endpoint Statistics application, we'll implement a combination of these strategies.

## Implementation Steps

### 1. Deployment Configuration

The deployment configuration establishes how the application runs in the cluster, including its replicas, labels, and probes for health monitoring.

```yaml
# k8s/deployment-strategy/flask-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-api
  namespace: endpoint-stats
  labels:
    app: flask-api
    component: api
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1         # Number of pods that can be created above desired count
      maxUnavailable: 0   # Number of pods that can be unavailable during update
  selector:
    matchLabels:
      app: flask-api
  template:
    metadata:
      labels:
        app: flask-api
        version: "1.0.0"  # Version label helps with traffic management
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9999"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: flask-api
        image: shreeraj1746/endpoint-stats:latest
        ports:
        - containerPort: 9999
          name: http
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        readinessProbe:   # Ensures traffic only goes to ready pods
          httpGet:
            path: /health
            port: 9999
          initialDelaySeconds: 5    # Wait time before first probe
          periodSeconds: 10         # Probe frequency
          timeoutSeconds: 2         # Probe timeout
          successThreshold: 1       # Success count required
          failureThreshold: 3       # Failure count before marking unready
        livenessProbe:    # Detects if app is running correctly
          httpGet:
            path: /health
            port: 9999
          initialDelaySeconds: 15
          periodSeconds: 20
          timeoutSeconds: 3
          failureThreshold: 3
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 10"]  # Grace period for connections to drain
      terminationGracePeriodSeconds: 30  # Time for pod to shut down gracefully
```

### 2. Rolling Updates

Rolling updates gradually replace old instances with new ones, ensuring zero downtime during the process.

```yaml
# rolling-update.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-api
  namespace: endpoint-stats
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%           # Allow 25% extra pods during update
      maxUnavailable: 25%     # Keep at least 75% of desired pods available
  template:
    metadata:
      annotations:
        kubernetes.io/change-cause: "Updating to version 2.0.0"  # Record change reason
    spec:
      containers:
      - name: flask-api
        image: shreeraj1746/endpoint-stats:v2.0.0
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 10"]  # Grace period for connections to drain
        terminationGracePeriodSeconds: 30  # Time for pod to shut down gracefully
```

### 3. Blue-Green Deployment

Blue-green deployments maintain two identical environments and switch traffic between them.

```yaml
# k8s/deployment-strategy/blue-green-deployment.yaml
---
# Blue deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-api-blue
  namespace: endpoint-stats
spec:
  replicas: 3
  selector:
    matchLabels:
      app: flask-api
      deployment: blue
  template:
    metadata:
      labels:
        app: flask-api
        deployment: blue
        version: "1.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9999"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: flask-api
        image: shreeraj1746/endpoint-stats:latest
        ports:
        - containerPort: 9999
        readinessProbe:
          httpGet:
            path: /health
            port: 9999
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
# Green deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-api-green
  namespace: endpoint-stats
spec:
  replicas: 0  # Start with 0 replicas, scale up when ready to switch
  selector:
    matchLabels:
      app: flask-api
      deployment: green
  template:
    metadata:
      labels:
        app: flask-api
        deployment: green
        version: "2.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9999"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: flask-api
        image: shreeraj1746/endpoint-stats:latest
        ports:
        - containerPort: 9999
        readinessProbe:
          httpGet:
            path: /health
            port: 9999
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
# Service to switch between blue and green
apiVersion: v1
kind: Service
metadata:
  name: flask-api-bg
  namespace: endpoint-stats
spec:
  selector:
    app: flask-api
    deployment: blue  # Switch to 'green' to route traffic to new version
  ports:
  - port: 9999
    targetPort: 9999
  type: ClusterIP
```

### 4. Canary Deployment

Canary deployments allow testing with a small subset of users before full rollout.

```yaml
# k8s/deployment-strategy/canary-deployment.yaml
---
# Canary deployment (small subset of traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-api-canary
  namespace: endpoint-stats
spec:
  replicas: 1  # Small subset (20% of traffic with 5 total replicas)
  selector:
    matchLabels:
      app: flask-api
      track: canary
  template:
    metadata:
      labels:
        app: flask-api
        track: canary
        version: "2.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9999"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: flask-api
        image: shreeraj1746/endpoint-stats:latest
        ports:
        - containerPort: 9999
        readinessProbe:
          httpGet:
            path: /health
            port: 9999
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
# Stable deployment (main traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-api-stable
  namespace: endpoint-stats
spec:
  replicas: 4  # Main traffic (80%)
  selector:
    matchLabels:
      app: flask-api
      track: stable
  template:
    metadata:
      labels:
        app: flask-api
        track: stable
        version: "1.0.0"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9999"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: flask-api
        image: shreeraj1746/endpoint-stats:latest
        ports:
        - containerPort: 9999
        readinessProbe:
          httpGet:
            path: /health
            port: 9999
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
# Service that selects both stable and canary deployments
apiVersion: v1
kind: Service
metadata:
  name: flask-api-canary
  namespace: endpoint-stats
spec:
  selector:
    app: flask-api  # Both stable and canary have this label
  ports:
  - port: 9999
    targetPort: 9999
  type: ClusterIP
```

### 3. Scaling Rules

Horizontal Pod Autoscaling (HPA) automatically adjusts the number of pods based on observed metrics.

```yaml
# k8s/deployment-strategy/flask-api-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: flask-api-hpa
  namespace: endpoint-stats
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: flask-api
  minReplicas: 2          # Minimum number of pods
  maxReplicas: 10         # Maximum number of pods
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Target CPU utilization
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Target memory utilization
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait before scaling down
      policies:
      - type: Percent
        value: 50                      # Scale down by 50% at a time
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0    # Scale up immediately
      policies:
      - type: Percent
        value: 100                     # Double pods if necessary
        periodSeconds: 60
      - type: Pods
        value: 4                       # But add max 4 pods per minute
        periodSeconds: 60
```

### 6. StatefulSet for Stateful Components

For stateful components like databases, StatefulSets provide stable identifiers and ordered operations.

```yaml
# postgres-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: endpoint-stats
spec:
  serviceName: "postgres"
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        env:
        - name: POSTGRES_DB
          value: endpoint_stats
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### 5. Deployment Scripts

Automation scripts help manage deployments and rollbacks efficiently.

```bash
# scripts/deploy.sh
#!/bin/bash
# deploy.sh - Script for deploying a new version of the Flask API

set -e  # Exit immediately if a command exits with non-zero status

# Default values
VERSION=${1:-latest}
NAMESPACE=${2:-endpoint-stats}
DEPLOYMENT=${3:-flask-api}

echo "Deploying $DEPLOYMENT version $VERSION to namespace $NAMESPACE"

# Update deployment
kubectl set image deployment/$DEPLOYMENT \
  $DEPLOYMENT=shreeraj1746/endpoint-stats:${VERSION} \
  -n $NAMESPACE

# Record the change for easier rollback
kubectl annotate deployment/$DEPLOYMENT kubernetes.io/change-cause="Deploying version $VERSION" --overwrite -n $NAMESPACE

# Monitor rollout
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

# Verify deployment
echo "Deployment complete. Verifying..."
echo "Pods:"
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide

echo "Deployment details:"
kubectl describe deployment $DEPLOYMENT -n $NAMESPACE | grep Image:

echo "Service endpoints:"
kubectl get endpoints -n $NAMESPACE | grep $DEPLOYMENT
```

### 6. Rollback Procedures

Configure safe rollbacks in case of deployment issues.

```bash
# scripts/rollback.sh
#!/bin/bash
# rollback.sh - Script for rolling back the Flask API to a previous version

set -e  # Exit immediately if a command exits with non-zero status

# Default values
DEPLOYMENT=${1:-flask-api}
NAMESPACE=${2:-endpoint-stats}
REVISION=${3:-0}  # 0 means previous, specific number to go further back

echo "Rolling back $DEPLOYMENT in namespace $NAMESPACE"

if [ "$REVISION" -eq "0" ]; then
  # Rollback to previous version
  kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
  kubectl annotate deployment/$DEPLOYMENT kubernetes.io/change-cause="Rollback to previous version" --overwrite -n $NAMESPACE
else
  # Rollback to specific revision
  kubectl rollout undo deployment/$DEPLOYMENT --to-revision=$REVISION -n $NAMESPACE
  kubectl annotate deployment/$DEPLOYMENT kubernetes.io/change-cause="Rollback to revision $REVISION" --overwrite -n $NAMESPACE
fi

# Monitor rollout
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

# Verify deployment
echo "Rollback complete. Verifying..."
echo "Pods:"
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide

echo "Rollout history:"
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE

echo "Current deployment details:"
kubectl describe deployment $DEPLOYMENT -n $NAMESPACE | grep Image:
```

### 7. CI/CD Integration

Integrating with CI/CD pipelines ensures automated testing and deployment.

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1

    - name: Login to DockerHub
      uses: docker/login-action@v1
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and push
      uses: docker/build-push-action@v2
      with:
        context: .
        push: ${{ github.event_name != 'pull_request' }}
        tags: shreeraj1746/endpoint-stats:latest,shreeraj1746/endpoint-stats:${{ github.sha }}

  deploy:
    needs: build
    if: github.event_name != 'pull_request'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

    - name: Set up Kubernetes
      uses: azure/k8s-set-context@v1
      with:
        kubeconfig: ${{ secrets.KUBE_CONFIG }}

    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/flask-api flask-api=shreeraj1746/endpoint-stats:${{ github.sha }} -n endpoint-stats
        kubectl rollout status deployment/flask-api -n endpoint-stats
```

### 7. Blue-Green Switching

Script for switching traffic between blue and green deployments:

```bash
# scripts/blue-green-switch.sh
#!/bin/bash
# blue-green-switch.sh - Script for switching traffic between blue and green deployments

set -e  # Exit immediately if a command exits with non-zero status

# Default values
NAMESPACE=${1:-endpoint-stats}
TARGET=${2:-green}  # Target environment to switch to (blue or green)
SERVICE_NAME=${3:-flask-api-bg}

# Validate target
if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
  echo "Error: TARGET must be either 'blue' or 'green'"
  exit 1
fi

echo "Switching $SERVICE_NAME to $TARGET environment in namespace $NAMESPACE"

# Update service selector
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"deployment\":\"$TARGET\"}}}"

# Verify the switch
echo "Service now pointing to $TARGET deployment"
kubectl describe service $SERVICE_NAME -n $NAMESPACE | grep -A3 "Selector:"

# Check endpoints
echo "Service endpoints:"
kubectl get endpoints -n $NAMESPACE | grep $SERVICE_NAME

# List pods
echo "Target deployment pods:"
kubectl get pods -n $NAMESPACE -l "app=flask-api,deployment=$TARGET" -o wide
```

### 8. Canary Traffic Adjustment

Script for adjusting the ratio of traffic between stable and canary deployments:

```bash
# scripts/canary-adjust.sh
#!/bin/bash
# canary-adjust.sh - Script for adjusting the traffic ratio between stable and canary deployments

set -e  # Exit immediately if a command exits with non-zero status

# Default values
NAMESPACE=${1:-endpoint-stats}
CANARY_PERCENT=${2:-20}  # Percentage of traffic to send to canary (0-100)
STABLE_DEPLOYMENT=${3:-flask-api-stable}
CANARY_DEPLOYMENT=${4:-flask-api-canary}
TOTAL_REPLICAS=${5:-5}  # Total number of replicas across both deployments

# Calculate replica counts
CANARY_REPLICAS=$(( ($TOTAL_REPLICAS * $CANARY_PERCENT) / 100 ))
STABLE_REPLICAS=$(( $TOTAL_REPLICAS - $CANARY_REPLICAS ))

# Validate canary percent
if [[ $CANARY_PERCENT -lt 0 || $CANARY_PERCENT -gt 100 ]]; then
  echo "Error: CANARY_PERCENT must be between 0 and 100"
  exit 1
fi

echo "Adjusting canary traffic to $CANARY_PERCENT% ($CANARY_REPLICAS of $TOTAL_REPLICAS replicas)"
echo "Stable: $STABLE_REPLICAS replicas, Canary: $CANARY_REPLICAS replicas"

# Update stable deployment
kubectl scale deployment $STABLE_DEPLOYMENT --replicas=$STABLE_REPLICAS -n $NAMESPACE

# Update canary deployment
kubectl scale deployment $CANARY_DEPLOYMENT --replicas=$CANARY_REPLICAS -n $NAMESPACE

# Monitor rollout for both deployments
echo "Monitoring stable deployment rollout..."
kubectl rollout status deployment/$STABLE_DEPLOYMENT -n $NAMESPACE

echo "Monitoring canary deployment rollout..."
kubectl rollout status deployment/$CANARY_DEPLOYMENT -n $NAMESPACE

# Verify the adjustment
echo "Deployment complete. Current pod counts:"
echo "Stable pods:"
kubectl get pods -n $NAMESPACE -l "app=flask-api,track=stable" | wc -l

echo "Canary pods:"
kubectl get pods -n $NAMESPACE -l "app=flask-api,track=canary" | wc -l

echo "All endpoint-stats pods:"
kubectl get pods -n $NAMESPACE -l "app=flask-api"
```

### 9. Database Service Alias

We created a service alias to handle the database hostname mismatch in the application:

```yaml
# k8s/db-alias-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: endpoint-stats
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

This service alias creates a service named "db" that points to the postgres database pods. It resolves the issue where the application is configured to connect to a database with hostname "db" instead of "postgres".

## Deployment Strategy Selection Guide

| Strategy | When to Use | Considerations |
|----------|-------------|---------------|
| Rolling Update | Default approach | Ensure readiness probes are configured properly |
| Blue-Green | High-risk changes requiring full testing | Requires double the resources temporarily |
| Canary | Features that need user feedback | Requires load balancing to split traffic |
| StatefulSet | Databases, message queues | Ordered scaling and unique identities |

## Implementation Checklist

- [x] Configure deployment strategy
- [x] Set up rolling updates
- [x] Configure blue-green deployment
- [x] Set up canary deployment
- [x] Implement scaling rules
- [x] Configure StatefulSets for stateful components
- [x] Create deployment scripts
- [x] Configure rollback procedures
- [x] Set up CI/CD integration
- [x] Test deployment process
- [x] Verify scaling behavior
- [x] Test rollback procedures
- [x] Document deployment procedures

## Troubleshooting Deployment Issues

1. **Failed deployments**:

   ```bash
   # Check rollout status
   kubectl rollout status deployment/flask-api -n endpoint-stats

   # View rollout history
   kubectl rollout history deployment/flask-api -n endpoint-stats

   # Check pod events
   kubectl describe pod -l app=flask-api -n endpoint-stats
   ```

2. **Image pull issues**:

   ```bash
   # Verify credentials
   kubectl get secret regcred -n endpoint-stats -o yaml

   # Check pod details
   kubectl describe pod -l app=flask-api -n endpoint-stats | grep -A10 Events
   ```

3. **Resource constraints**:

   ```bash
   # Check node resources
   kubectl describe nodes | grep -A10 Allocated

   # Check pod resource usage
   kubectl top pods -n endpoint-stats
   ```

4. **Database connectivity issues**:

   ```bash
   # Check if the database service exists
   kubectl get service db -n endpoint-stats

   # Check if the database is running
   kubectl get pods -n endpoint-stats -l app=postgres

   # Check database logs
   kubectl logs -n endpoint-stats -l app=postgres

   # Check application logs for connection errors
   kubectl logs -n endpoint-stats -l app=flask-api
   ```

## Next Steps

After completing Phase 4, proceed to [Phase 5: Monitoring and Maintenance](impl_phase5.md) to implement monitoring and maintenance procedures.
