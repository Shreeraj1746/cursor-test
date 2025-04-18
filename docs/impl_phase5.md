# Phase 5: Monitoring and Maintenance

## Overview

This phase focuses on implementing comprehensive monitoring and maintenance procedures for the Endpoint Statistics application. We'll set up monitoring dashboards, backup procedures, maintenance protocols, and disaster recovery plans to ensure system reliability and data safety. These measures are crucial for long-term application stability and performance.

## Monitoring Philosophy

Effective monitoring follows these principles:

- **Proactive vs. Reactive**: Detect issues before they affect users
- **Actionable Alerts**: Every alert should be meaningful and require action
- **Comprehensive Coverage**: Monitor all components, dependencies, and user-facing services
- **Performance Insights**: Track trends over time to predict future needs

## Implementation Steps

### 1. Grafana Dashboard Setup

Grafana dashboards provide visual representations of system metrics, making it easy to monitor application health and performance.

```yaml
# endpoint-stats-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: endpoint-stats-dashboard
  namespace: endpoint-stats
data:
  dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Endpoint Statistics Dashboard",
        "refresh": "10s",
        "time": {
          "from": "now-6h",
          "to": "now"
        },
        "timepicker": {
          "refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"],
          "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]
        },
        "panels": [
          {
            "id": 1,
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
            "title": "Request Rate by Endpoint",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total[5m])) by (path)",
                "legendFormat": "{{path}}"
              }
            ],
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            }
          },
          {
            "id": 2,
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
            "title": "Error Rate",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (path)",
                "legendFormat": "{{path}}"
              }
            ]
          },
          {
            "id": 3,
            "gridPos": {"h": 8, "w": 8, "x": 0, "y": 8},
            "title": "CPU Usage",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"endpoint-stats\"}[5m])) by (pod)",
                "legendFormat": "{{pod}}"
              }
            ]
          },
          {
            "id": 4,
            "gridPos": {"h": 8, "w": 8, "x": 8, "y": 8},
            "title": "Memory Usage",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(container_memory_usage_bytes{namespace=\"endpoint-stats\"}) by (pod)",
                "legendFormat": "{{pod}}",
                "format": "bytes"
              }
            ]
          },
          {
            "id": 5,
            "gridPos": {"h": 8, "w": 8, "x": 16, "y": 8},
            "title": "Response Time by Endpoint",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path))",
                "legendFormat": "{{path}} (p95)"
              },
              {
                "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path))",
                "legendFormat": "{{path}} (p50)"
              }
            ]
          },
          {
            "id": 6,
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16},
            "title": "Pod Status",
            "type": "stat",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(kube_pod_status_phase{namespace=\"endpoint-stats\", phase=\"Running\"}) by (pod)"
              }
            ],
            "options": {
              "colorMode": "value",
              "graphMode": "area",
              "justifyMode": "auto",
              "orientation": "auto",
              "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": false
              }
            }
          }
        ],
        "templating": {
          "list": [
            {
              "name": "pod",
              "type": "query",
              "datasource": "Prometheus",
              "query": "label_values(kube_pod_info{namespace=\"endpoint-stats\"}, pod)",
              "refresh": 1,
              "regex": "",
              "sort": 0,
              "multi": true
            }
          ]
        },
        "annotations": {
          "list": [
            {
              "name": "Deployments",
              "datasource": "Prometheus",
              "expr": "changes(kube_deployment_status_replicas_updated{namespace=\"endpoint-stats\"}[5m]) > 0",
              "step": "60s",
              "titleFormat": "Deployment",
              "tagKeys": "deployment",
              "textFormat": "Deployment {{deployment}} updated"
            }
          ]
        }
      }
    }
```

#### Advanced Grafana Dashboard Configuration

```yaml
# advanced-dashboard-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: advanced-endpoint-stats-dashboard
  namespace: endpoint-stats
data:
  dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Endpoint Statistics Advanced Dashboard",
        "refresh": "10s",
        "time": {
          "from": "now-6h",
          "to": "now"
        },
        "timepicker": {
          "refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"],
          "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]
        },
        "panels": [
          {
            "id": 1,
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
            "title": "Request Rate by Endpoint",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total[5m])) by (path)",
                "legendFormat": "{{path}}"
              }
            ],
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "xaxis": {
              "mode": "time",
              "show": true
            },
            "yaxes": [
              {
                "format": "short",
                "label": "Requests/second",
                "logBase": 1,
                "show": true
              },
              {
                "format": "short",
                "logBase": 1,
                "show": true
              }
            ]
          },
          {
            "id": 2,
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
            "title": "Response Time by Endpoint",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path))",
                "legendFormat": "{{path}} (p95)"
              },
              {
                "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path))",
                "legendFormat": "{{path}} (p50)"
              }
            ]
          },
          {
            "id": 3,
            "gridPos": {"h": 8, "w": 8, "x": 0, "y": 8},
            "title": "CPU Usage",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"endpoint-stats\"}[5m])) by (pod)",
                "legendFormat": "{{pod}}"
              }
            ]
          },
          {
            "id": 4,
            "gridPos": {"h": 8, "w": 8, "x": 8, "y": 8},
            "title": "Memory Usage",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(container_memory_usage_bytes{namespace=\"endpoint-stats\"}) by (pod)",
                "legendFormat": "{{pod}}",
                "format": "bytes"
              }
            ]
          },
          {
            "id": 5,
            "gridPos": {"h": 8, "w": 8, "x": 16, "y": 8},
            "title": "Pod Status",
            "type": "stat",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(kube_pod_status_phase{namespace=\"endpoint-stats\", phase=\"Running\"}) by (pod)"
              }
            ],
            "options": {
              "colorMode": "value",
              "graphMode": "area",
              "justifyMode": "auto",
              "orientation": "auto",
              "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": false
              }
            }
          },
          {
            "id": 6,
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16},
            "title": "Error Rate by Status Code",
            "type": "graph",
            "datasource": "Prometheus",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (status, path)",
                "legendFormat": "{{status}} - {{path}}"
              }
            ]
          }
        ],
        "templating": {
          "list": [
            {
              "name": "pod",
              "type": "query",
              "datasource": "Prometheus",
              "query": "label_values(kube_pod_info{namespace=\"endpoint-stats\"}, pod)",
              "refresh": 1,
              "regex": "",
              "sort": 0,
              "multi": true
            }
          ]
        },
        "annotations": {
          "list": [
            {
              "name": "Deployments",
              "datasource": "Prometheus",
              "expr": "changes(kube_deployment_status_replicas_updated{namespace=\"endpoint-stats\"}[5m]) > 0",
              "step": "60s",
              "titleFormat": "Deployment",
              "tagKeys": "deployment",
              "textFormat": "Deployment {{deployment}} updated"
            }
          ]
        }
      }
    }
```

### 2. Backup Procedures

Backups are essential for data recovery in case of system failures or data corruption. We'll implement automated backup procedures for both databases and configuration data.

```yaml
# backup-job.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: endpoint-stats
spec:
  schedule: "0 0 * * *"  # Daily at midnight
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:14
            command: ["/bin/sh", "-c"]
            args:
            - |
              pg_dump -h postgres -U admin -d endpoint_stats > /backup/backup-$(date +%Y%m%d).sql

              # Cleanup old backups (keep last 10 days)
              find /backup -name "backup-*.sql" -type f -mtime +10 -delete

              # Log backup completion
              echo "Backup completed at $(date)" >> /backup/backup.log
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
          volumes:
          - name: backup-volume
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

We also need a persistent volume claim for the backups:

```yaml
# backup-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: endpoint-stats
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

#### Backup Verification and Testing

To ensure our backups are valid and can be restored if needed, we implement a verification job:

```yaml
# backup-verify-job.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-verification
  namespace: endpoint-stats
spec:
  schedule: "0 4 * * *"  # Run daily at 4 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: verify
            image: postgres:14
            command: ["/bin/sh", "-c"]
            args:
            - |
              # Find the most recent backup
              LATEST_BACKUP=$(find /backup -name "backup-*.sql" -type f -printf "%T@ %p\n" | sort -n | tail -1 | cut -f2- -d" ")

              if [ -z "$LATEST_BACKUP" ]; then
                echo "No backups found!" | tee -a /backup/verification.log
                exit 1
              fi

              echo "Verifying backup: $LATEST_BACKUP" | tee -a /backup/verification.log

              # Create a temporary database for testing
              export PGPASSWORD="$POSTGRES_PASSWORD"
              psql -h postgres -U admin -d postgres -c "DROP DATABASE IF EXISTS backup_verify;"
              psql -h postgres -U admin -d postgres -c "CREATE DATABASE backup_verify;"

              # Restore the backup to the test database
              psql -h postgres -U admin -d backup_verify < $LATEST_BACKUP

              # Run some basic validation queries
              ROW_COUNT=$(psql -h postgres -U admin -d backup_verify -t -c "SELECT count(*) FROM endpoints;")

              echo "Verification complete. Row count: $ROW_COUNT" | tee -a /backup/verification.log

              # Clean up
              psql -h postgres -U admin -d postgres -c "DROP DATABASE backup_verify;"

              # Save verification results
              echo "$(date) - Backup $LATEST_BACKUP verified successfully. Row count: $ROW_COUNT" >> /backup/verification.log

              # Exit with error if row count is 0 (possible empty backup)
              if [ "$ROW_COUNT" -eq "0" ]; then
                echo "ERROR: Backup contains no data!" | tee -a /backup/verification.log
                exit 1
              fi
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
            env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
          volumes:
          - name: backup-volume
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

### 3. Disaster Recovery Plan

A disaster recovery plan outlines procedures for recovering from various failure scenarios, from service outages to complete data center failures.

```yaml
# disaster-recovery-plan.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: disaster-recovery-plan
  namespace: endpoint-stats
data:
  dr-plan.md: |
    # Disaster Recovery Plan for Endpoint Statistics Application

    ## Recovery Point Objective (RPO)
    The application aims for an RPO of 1 hour, meaning no more than 1 hour of data should be lost in case of a disaster.

    ## Recovery Time Objective (RTO)
    The application aims for an RTO of 4 hours, meaning the application should be back online within 4 hours of a disaster.

    ## Disaster Scenarios and Recovery Procedures

    ### Scenario 1: Database Failure

    1. Identify the failure cause
    2. If it's a pod or node issue, allow Kubernetes to reschedule the pod
    3. If data is corrupted, restore from the most recent backup:
       ```
       cd /path/to/project
       ./scripts/dr-restore.sh
       ```

    ### Scenario 2: Complete Cluster Failure

    1. Provision a new Kubernetes cluster
    2. Install monitoring components:
       ```
       kubectl apply -f k8s/namespace.yaml
       kubectl apply -f k8s/monitoring/
       ```
    3. Restore persistent volumes:
       ```
       kubectl apply -f k8s/persistent-volumes.yaml
       kubectl apply -f k8s/maintenance/backup-pvc.yaml
       ```
    4. Deploy database:
       ```
       kubectl apply -f k8s/secrets.yaml
       kubectl apply -f k8s/postgres.yaml
       kubectl apply -f k8s/db-alias-service.yaml
       ```
    5. Restore database from backup:
       ```
       ./scripts/dr-restore.sh /path/to/offsite/backup.sql
       ```
    6. Deploy Redis:
       ```
       kubectl apply -f k8s/redis.yml
       ```
    7. Deploy application:
       ```
       kubectl apply -f k8s/flask-api.yaml
       ```
    8. Deploy ingress:
       ```
       kubectl apply -f k8s/ingress.yaml
       ```
    9. Update DNS records to point to the new cluster

    ### Scenario 3: Application Deployment Failure

    1. Identify the failing deployment
    2. Roll back to the last known good version:
       ```
       kubectl rollout undo deployment/flask-api -n endpoint-stats
       ```
    3. Review logs to determine the root cause:
       ```
       kubectl logs -n endpoint-stats deployment/flask-api
       ```

    ## Recovery Testing Schedule
    DR recovery procedures should be tested quarterly to ensure they work as expected.

    ### Testing Procedure

    1. Schedule a test window during off-peak hours
    2. Create a separate test namespace:
       ```
       kubectl create namespace endpoint-stats-dr-test
       ```
    3. Copy production configurations to test namespace
    4. Restore a recent backup to the test environment
    5. Validate functionality
    6. Document results and any issues encountered
    7. Clean up test environment:
       ```
       kubectl delete namespace endpoint-stats-dr-test
       ```
```

#### Disaster Recovery Scripts

Here's our database restore script for disaster recovery:

```bash
#!/bin/bash
# dr-restore.sh

set -e

# Parameters
BACKUP_FILE=${1:-$(find /backup -name "backup-*.sql" -type f -printf "%T@ %p\n" | sort -n | tail -1 | cut -f2- -d" ")}
NAMESPACE="endpoint-stats"
DATABASE_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o name | head -1)

if [ -z "$BACKUP_FILE" ]; then
  echo "Error: No backup file specified and none found in /backup directory"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file $BACKUP_FILE does not exist"
  exit 1
fi

echo "Starting disaster recovery restore from backup: $BACKUP_FILE"

# 1. Create temporary database dump folder
echo "Creating temporary folder in pod..."
kubectl exec -n $NAMESPACE ${DATABASE_POD} -- mkdir -p /tmp/restore

# 2. Copy backup file to pod
echo "Copying backup file to pod..."
kubectl cp $BACKUP_FILE $NAMESPACE/${DATABASE_POD#*/}:/tmp/restore/backup.sql

# 3. Restore the database
echo "Restoring database..."
kubectl exec -n $NAMESPACE ${DATABASE_POD} -- bash -c "
export PGPASSWORD=\$(cat /etc/postgres-secret/password);
psql -U admin -d postgres -c 'DROP DATABASE IF EXISTS endpoint_stats;'
psql -U admin -d postgres -c 'CREATE DATABASE endpoint_stats;'
psql -U admin -d endpoint_stats < /tmp/restore/backup.sql
"

# 4. Verify restoration
echo "Verifying restoration..."
ROW_COUNT=$(kubectl exec -n $NAMESPACE ${DATABASE_POD} -- bash -c "
export PGPASSWORD=\$(cat /etc/postgres-secret/password);
psql -U admin -d endpoint_stats -t -c 'SELECT count(*) FROM endpoints;'
")

echo "Restoration complete. Row count: $ROW_COUNT"

# 5. Clean up
echo "Cleaning up..."
kubectl exec -n $NAMESPACE ${DATABASE_POD} -- rm -rf /tmp/restore

# 6. Restart applications to ensure they reconnect properly
echo "Restarting applications..."
kubectl rollout restart deployment -n $NAMESPACE flask-api

echo "Disaster recovery completed successfully!"
```

### 4. Maintenance Procedures

Regular system maintenance helps prevent issues and optimize performance. We'll implement scheduled maintenance tasks for database optimization, log rotation, and system updates.

First, we'll create a service account with appropriate permissions for maintenance tasks:

```yaml
# maintenance-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: maintenance-sa
  namespace: endpoint-stats
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: maintenance-role
  namespace: endpoint-stats
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: maintenance-rolebinding
  namespace: endpoint-stats
subjects:
- kind: ServiceAccount
  name: maintenance-sa
  namespace: endpoint-stats
roleRef:
  kind: Role
  name: maintenance-role
  apiGroup: rbac.authorization.k8s.io
```

Then, we'll set up a comprehensive maintenance job that runs on a schedule:

```yaml
# system-maintenance.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: system-maintenance
  namespace: endpoint-stats
spec:
  schedule: "0 2 * * *"  # Run daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: maintenance-sa
          containers:
          - name: maintenance
            image: bitnami/kubectl:latest
            command: ["/bin/bash", "-c"]
            args:
            - |
              # 1. Database maintenance
              echo "Running database maintenance..."
              kubectl exec -n endpoint-stats $(kubectl get pods -n endpoint-stats -l app=postgres -o name | head -1) -- bash -c "
                export PGPASSWORD=\$(cat /etc/postgres-secret/password);
                # Analyze tables to update statistics
                psql -U admin -d endpoint_stats -c 'VACUUM ANALYZE;'
                # Remove dead rows to reclaim space
                psql -U admin -d endpoint_stats -c 'VACUUM FULL;'
                # Rebuild indices
                psql -U admin -d endpoint_stats -c 'REINDEX DATABASE endpoint_stats;'
                # Cleanup temporary objects
                psql -U admin -d endpoint_stats -c 'DROP TABLE IF EXISTS temp_stats;'
              "

              # 2. Redis maintenance
              echo "Running Redis maintenance..."
              kubectl exec -n endpoint-stats $(kubectl get pods -n endpoint-stats -l app=redis -o name | head -1) -- bash -c "
                # Remove old cache entries
                redis-cli --raw -h localhost keys 'cache:*' | xargs -r redis-cli del
                # Run memory optimization
                redis-cli --raw -h localhost MEMORY PURGE
                # Save current dataset
                redis-cli --raw -h localhost SAVE
              "

              # 3. Log rotation and cleanup
              echo "Cleaning old logs..."
              kubectl get pods -n endpoint-stats --no-headers | awk '{print $1}' | xargs -I{} kubectl exec -n endpoint-stats {} -- bash -c "
                if [ -d /var/log ]; then
                  find /var/log -type f -name '*.log' -mtime +7 -delete || true
                fi
              " || true

              # 4. Clear old completed jobs
              echo "Cleaning old jobs..."
              kubectl delete jobs -n endpoint-stats --field-selector status.successful=1 --field-selector status.completionTime\\<$(date -d '7 days ago' -Ins)

              # 5. Report maintenance completion
              echo "Maintenance completed at $(date)"
            volumeMounts:
            - name: maintenance-volume
              mountPath: /maintenance
          volumes:
          - name: maintenance-volume
            emptyDir: {}
          restartPolicy: OnFailure
```

### 5. Health Check Scripts

Health check scripts help monitor the system and quickly identify issues. Our comprehensive health check script gathers important metrics and information about all key components:

```bash
#!/bin/bash
# health-check.sh
# Usage: ./health-check.sh [output_file]

OUTPUT_FILE=${1:-"health-report.txt"}
NAMESPACE="endpoint-stats"

# Start fresh report
echo "Endpoint Statistics Health Report - $(date)" > $OUTPUT_FILE
echo "=================================================" >> $OUTPUT_FILE

# 1. Check all pod statuses
echo -e "\n## Pod Status" >> $OUTPUT_FILE
kubectl get pods -n $NAMESPACE -o wide >> $OUTPUT_FILE

# 2. Check recent pod events
echo -e "\n## Recent Pod Events" >> $OUTPUT_FILE
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10 >> $OUTPUT_FILE

# 3. Check resource usage
echo -e "\n## Resource Usage" >> $OUTPUT_FILE
echo "CPU and Memory:" >> $OUTPUT_FILE
kubectl top pods -n $NAMESPACE >> $OUTPUT_FILE

# 4. Check API health
echo -e "\n## API Health" >> $OUTPUT_FILE
API_POD=$(kubectl get pods -n $NAMESPACE -l app=flask-api -o name | head -1)
if [ -n "$API_POD" ]; then
  kubectl exec -n $NAMESPACE $API_POD -- curl -s http://localhost:5000/health >> $OUTPUT_FILE
else
  echo "No API pod found!" >> $OUTPUT_FILE
fi

# 5. Database checks
echo -e "\n## Database Health" >> $OUTPUT_FILE
DB_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o name | head -1)
if [ -n "$DB_POD" ]; then
  echo "Connection test:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $DB_POD -- bash -c "PGPASSWORD=\$(cat /etc/postgres-secret/password) psql -U admin -d endpoint_stats -c 'SELECT 1;'" >> $OUTPUT_FILE

  echo "Database size:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $DB_POD -- bash -c "PGPASSWORD=\$(cat /etc/postgres-secret/password) psql -U admin -d endpoint_stats -c 'SELECT pg_size_pretty(pg_database_size(\"endpoint_stats\"));'" >> $OUTPUT_FILE

  echo "Connection count:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $DB_POD -- bash -c "PGPASSWORD=\$(cat /etc/postgres-secret/password) psql -U admin -d endpoint_stats -c 'SELECT count(*) FROM pg_stat_activity;'" >> $OUTPUT_FILE
else
  echo "No database pod found!" >> $OUTPUT_FILE
fi

# 6. Redis checks
echo -e "\n## Redis Health" >> $OUTPUT_FILE
REDIS_POD=$(kubectl get pods -n $NAMESPACE -l app=redis -o name | head -1)
if [ -n "$REDIS_POD" ]; then
  echo "Connection test:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $REDIS_POD -- redis-cli PING >> $OUTPUT_FILE

  echo "Memory usage:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $REDIS_POD -- redis-cli INFO memory | grep used_memory_human >> $OUTPUT_FILE

  echo "Client count:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $REDIS_POD -- redis-cli INFO clients | grep connected_clients >> $OUTPUT_FILE
else
  echo "No Redis pod found!" >> $OUTPUT_FILE
fi

# 7. Check PVC status
echo -e "\n## Storage Status" >> $OUTPUT_FILE
kubectl get pvc -n $NAMESPACE >> $OUTPUT_FILE

# 8. Check recent logs
echo -e "\n## Recent API Logs" >> $OUTPUT_FILE
if [ -n "$API_POD" ]; then
  kubectl logs -n $NAMESPACE $API_POD --tail=20 >> $OUTPUT_FILE
fi

# Display report
cat $OUTPUT_FILE

echo -e "\nHealth check complete. Report saved to $OUTPUT_FILE"
```

### 6. Monitoring Alerts

Monitoring alerts notify operators of system issues that require attention. We'll configure Prometheus alerts for monitoring our application:

```yaml
# endpoint-stats-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: endpoint-stats-alerts
  namespace: endpoint-stats
spec:
  groups:
  - name: endpoint-stats
    rules:
    - alert: HighErrorRate
      expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05
      for: 5m
      labels:
        severity: critical
        team: engineering
      annotations:
        summary: High error rate detected
        description: Error rate is above 5% for 5 minutes
        runbook: "https://wiki.example.com/runbooks/high-error-rate"

    - alert: SlowResponseTime
      expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 1
      for: 5m
      labels:
        severity: warning
        team: engineering
      annotations:
        summary: Slow API response time detected
        description: 95th percentile response time is above 1 second
        runbook: "https://wiki.example.com/runbooks/slow-response-time"

    - alert: DatabaseConnectionIssues
      expr: up{job="postgres-exporter"} == 0
      for: 1m
      labels:
        severity: critical
        team: dba
      annotations:
        summary: Database connection issues
        description: Cannot connect to PostgreSQL database
        runbook: "https://wiki.example.com/runbooks/database-connection-issues"

    - alert: RedisConnectionIssues
      expr: up{job="redis-exporter"} == 0
      for: 1m
      labels:
        severity: critical
        team: engineering
      annotations:
        summary: Redis connection issues
        description: Cannot connect to Redis cache
        runbook: "https://wiki.example.com/runbooks/redis-connection-issues"

    - alert: HighCPUUsage
      expr: sum(rate(container_cpu_usage_seconds_total{namespace="endpoint-stats"}[5m])) by (pod) / sum(kube_pod_container_resource_limits_cpu_cores{namespace="endpoint-stats"}) by (pod) > 0.8
      for: 10m
      labels:
        severity: warning
        team: operations
      annotations:
        summary: High CPU usage
        description: Pod {{ $labels.pod }} is using more than 80% of its CPU limit for 10 minutes
        runbook: "https://wiki.example.com/runbooks/high-cpu-usage"

    - alert: HighMemoryUsage
      expr: sum(container_memory_usage_bytes{namespace="endpoint-stats"}) by (pod) / sum(kube_pod_container_resource_limits_memory_bytes{namespace="endpoint-stats"}) by (pod) > 0.8
      for: 10m
      labels:
        severity: warning
        team: operations
      annotations:
        summary: High memory usage
        description: Pod {{ $labels.pod }} is using more than 80% of its memory limit for 10 minutes
        runbook: "https://wiki.example.com/runbooks/high-memory-usage"

    - alert: PodRestartingFrequently
      expr: increase(kube_pod_container_status_restarts_total{namespace="endpoint-stats"}[1h]) > 5
      labels:
        severity: warning
        team: engineering
      annotations:
        summary: Pod restarting frequently
        description: Pod {{ $labels.pod }} has restarted more than 5 times in the last hour
        runbook: "https://wiki.example.com/runbooks/pod-restarting"
```

### 7. Performance Tuning Guidelines

Recommendations for optimizing application performance based on metrics.

```yaml
# performance-tuning-guide.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: performance-tuning-guide
  namespace: endpoint-stats
data:
  tuning-guide.md: |
    # Performance Tuning Guide for Endpoint Statistics

    ## Resource Allocation Guidelines

    ### Flask API
    - Start with 100m CPU, 128Mi memory per pod
    - For every 100 req/s, add approximately 50m CPU
    - For heavy statistical analysis workloads, increase memory to 256Mi per pod
    - Optimal pod count: 3-5 for typical workloads

    ### PostgreSQL
    - For databases under 10GB: 500m CPU, 1Gi memory
    - For databases 10-50GB: 1000m CPU, 2Gi memory
    - For databases over 50GB: 2000m CPU, 4Gi memory
    - Consider read replicas for heavy read workloads

    ### Redis
    - For caching only: 100m CPU, 256Mi memory
    - With persistent storage: 200m CPU, 512Mi memory
    - Consider Redis Cluster for datasets > 2GB

    ## Query Optimization

    ### Common Slow Queries and Solutions
    1. Endpoint statistics aggregation:
       ```sql
       -- Original slow query
       SELECT endpoint, COUNT(*), AVG(response_time)
       FROM requests
       WHERE timestamp > NOW() - INTERVAL '30 days'
       GROUP BY endpoint;

       -- Optimized query
       SELECT endpoint, COUNT(*), AVG(response_time)
       FROM requests
       WHERE timestamp > NOW() - INTERVAL '30 days'
       GROUP BY endpoint
       ORDER BY COUNT(*) DESC
       LIMIT 10;
       ```

    2. Add appropriate indices:
       ```sql
       CREATE INDEX idx_requests_timestamp ON requests(timestamp);
       CREATE INDEX idx_requests_endpoint ON requests(endpoint);
       CREATE INDEX idx_requests_endpoint_timestamp ON requests(endpoint, timestamp);
       ```

    3. Pre-aggregate commonly accessed statistics in a materialized view:
       ```sql
       CREATE MATERIALIZED VIEW endpoint_daily_stats AS
       SELECT
         endpoint,
         DATE_TRUNC('day', timestamp) AS day,
         COUNT(*) AS request_count,
         AVG(response_time) AS avg_response_time,
         MAX(response_time) AS max_response_time,
         MIN(response_time) AS min_response_time,
         SUM(CASE WHEN status >= 500 THEN 1 ELSE 0 END) AS error_count
       FROM requests
       GROUP BY endpoint, DATE_TRUNC('day', timestamp);

       CREATE INDEX idx_endpoint_daily_stats_endpoint ON endpoint_daily_stats(endpoint);
       CREATE INDEX idx_endpoint_daily_stats_day ON endpoint_daily_stats(day);
       ```

    4. Update materialized view periodically:
       ```sql
       REFRESH MATERIALIZED VIEW endpoint_daily_stats;
       ```

    ## Scaling Guidelines

    - Set HPA targets at 70% CPU to allow buffer for traffic spikes
    - Implement PodDisruptionBudgets for critical components
    - Pre-scale before expected high-traffic events
    - Use node anti-affinity to spread pods across nodes

    ## Caching Strategy

    1. Use Redis for API-level caching with appropriate TTLs:
       - High-change data: 1-5 minutes
       - Medium-change data: 30-60 minutes
       - Reference data: 12-24 hours

    2. Implement HTTP caching headers for client-side caching:
       ```python
       @app.route('/api/endpoint-stats/<endpoint_id>')
       def get_endpoint_stats(endpoint_id):
           # ... fetch data ...
           response = jsonify(stats)
           response.cache_control.max_age = 300  # 5 minutes
           response.cache_control.public = True
           return response
       ```

    ## Connection Pooling

    - Database connections: Min 5, Max 20 per pod
    - Redis connections: Min 2, Max 10 per pod
    - Example database connection pool configuration:
      ```python
      db_pool = sqlalchemy.create_engine(
          'postgresql://admin:password@postgres/endpoint_stats',
          pool_size=10,
          max_overflow=10,
          pool_timeout=30,
          pool_recycle=1800
      )
      ```

    ## Network Optimization

    - Use keepalive connections between components
    - Configure appropriate timeouts
    - Consider using a service mesh for advanced traffic management

    ## Regular Maintenance Tasks

    1. Database:
       - VACUUM ANALYZE: Weekly
       - REINDEX: Monthly
       - Update statistics: Daily

    2. Application:
       - Log rotation: Daily
       - Cache cleanup: Daily
       - Temporary file cleanup: Daily
```

### 8. Capacity Planning

A strategy for planning resource capacity based on growth projections.

```yaml
# capacity-planning.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: capacity-planning
  namespace: endpoint-stats
data:
  capacity-plan.md: |
    # Capacity Planning for Endpoint Statistics

    ## Current Resource Usage (Baseline)

    | Component | Current Pods | CPU/Pod | Memory/Pod | Storage |
    |-----------|--------------|---------|------------|---------|
    | Flask API | 3            | 100m    | 128Mi      | N/A     |
    | PostgreSQL| 1            | 500m    | 1Gi        | 10Gi    |
    | Redis     | 1            | 100m    | 256Mi      | 5Gi     |

    ## Growth Projections

    | Metric             | Current | 3 Months | 6 Months | 12 Months |
    |--------------------|---------|----------|----------|-----------|
    | Requests/second    | 100     | 250      | 500      | 1000      |
    | Database size (GB) | 5       | 8        | 15       | 30        |
    | Cache size (GB)    | 1       | 2        | 3        | 5         |
    | Endpoints tracked  | 1000    | 2500     | 5000     | 10000     |

    ## Resource Scaling Plan

    ### 3 Months
    - Scale Flask API to 5 pods
    - Increase PostgreSQL to 750m CPU, 1.5Gi memory
    - No changes needed for Redis

    ### 6 Months
    - Scale Flask API to 8 pods
    - Increase PostgreSQL to 1000m CPU, 2Gi memory
    - Increase PostgreSQL storage to 20Gi
    - Increase Redis to 200m CPU, 512Mi memory

    ### 12 Months
    - Scale Flask API to 15 pods
    - Consider database sharding or read replicas
    - Increase PostgreSQL to 2000m CPU, 4Gi memory, 50Gi storage
    - Increase Redis to 500m CPU, 1Gi memory, 10Gi storage
    - Implement Redis Cluster for better scalability

    ## Node Capacity Planning

    For 12-month projections, minimum node requirements:
    - Worker nodes: 5 (8 CPU, 32GB RAM each)
    - Consider dedicated nodes for database workloads
    - Implement autoscaling at the node level

    ## Cost Projections

    | Timeframe | Estimated Monthly Cost |
    |-----------|------------------------|
    | Current   | $500                   |
    | 3 Months  | $700                   |
    | 6 Months  | $1200                  |
    | 12 Months | $2000                  |

    ## Data Retention Policy

    | Data Type           | Retention Period | Storage Impact |
    |---------------------|------------------|----------------|
    | Raw request logs    | 30 days          | ~10GB/month    |
    | Aggregated metrics  | 1 year           | ~1GB/month     |
    | System logs         | 14 days          | ~2GB/month     |

    ## Performance Scaling Thresholds

    | Metric                | Warning Threshold | Critical Threshold | Action                           |
    |-----------------------|-------------------|--------------------|---------------------------------|
    | CPU Utilization       | 70%               | 85%                | Scale up pods                    |
    | Memory Utilization    | 75%               | 90%                | Scale up pods                    |
    | Database Connections  | 80%               | 95%                | Increase connection pool         |
    | Response Time (p95)   | 500ms             | 1000ms             | Optimize queries, scale up       |
    | Disk Usage            | 70%               | 85%                | Increase storage, clean old data |

    ## Monitoring and Review Schedule

    - Daily: Review basic metrics and alerts
    - Weekly: Analyze performance trends and capacity usage
    - Monthly: Update capacity projections based on actual usage
    - Quarterly: Comprehensive capacity review and planning
```

### 9. Log Retention Policy

Managing log retention ensures we meet compliance requirements while efficiently using storage resources.

```yaml
# log-retention-policy.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: log-retention-policy
  namespace: endpoint-stats
data:
  policy.md: |
    # Log Retention Policy

    ## Retention Periods

    | Log Type       | Retention Period | Storage Location |
    |---------------|------------------|------------------|
    | Application   | 30 days          | Elasticsearch    |
    | System        | 14 days          | Elasticsearch    |
    | Security      | 365 days         | Secured storage  |
    | Audit         | 180 days         | Secured storage  |
    | Performance   | 7 days           | Elasticsearch    |

    ## Compliance Requirements

    For regulated industries, adjust retention periods to:
    - Financial services: Minimum 7 years for transaction logs
    - Healthcare: Minimum 6 years for access logs
    - PCI-DSS: Minimum 1 year for authentication logs

    ## Log Rotation Configuration

    Logs will be rotated as follows:
    - Size-based rotation: When log file reaches 100MB
    - Time-based rotation: Daily at midnight

    ## Archival Procedure

    1. Logs older than retention period are compressed
    2. Compressed logs are moved to cold storage
    3. Verification of archived logs is performed monthly

    ## Log Collection and Forwarding

    - Application logs are collected via Fluentd agents
    - System logs are collected via node-level logging agents
    - All logs are forwarded to central Elasticsearch cluster
    - Critical security events trigger real-time alerts

    ## Log Categories and Severity Levels

    | Category | Examples | Minimum Severity to Store |
    |----------|----------|--------------------------|
    | Security | Authentication attempts, permission changes | INFO |
    | Performance | API response times, resource usage | WARNING |
    | Application | API requests, business logic | INFO |
    | System | Node events, pod scheduling | WARNING |
    | Audit | Data access, configuration changes | INFO |

    ## Log Format Standards

    All logs should follow the structured JSON format:
    ```json
    {
      "timestamp": "2025-04-18T14:32:15Z",
      "level": "INFO",
      "category": "application",
      "service": "flask-api",
      "message": "Request processed successfully",
      "context": {
        "request_id": "abc-123",
        "user_id": "user-456",
        "endpoint": "/api/stats"
      },
      "metrics": {
        "duration_ms": 45,
        "status_code": 200
      }
    }
    ```
```

## Implementation Checklist

- [x] Set up Grafana dashboards
- [x] Configure monitoring visualizations
- [x] Configure backup procedures
- [x] Set up backup verification and testing
- [x] Create disaster recovery plan and scripts
- [x] Implement maintenance automation
- [x] Create health check scripts
- [x] Configure monitoring alerts
- [x] Document performance tuning guidelines
- [x] Create capacity planning document
- [x] Document log retention policy
- [x] Test backup and restore
- [x] Verify monitoring setup
- [x] Document maintenance procedures

## Next Steps

After completing Phase 5, we have successfully implemented all major components of the Endpoint Statistics application. The monitoring and maintenance capabilities ensure our system will be reliable, performant, and maintainable in the long term.

Some additional improvements to consider for the future:
- Implement automated scale testing
- Set up external monitoring for outside-in perspective
- Configure multi-region disaster recovery
- Implement advanced anomaly detection
