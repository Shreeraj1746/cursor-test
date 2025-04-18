#!/bin/bash
# Script to backup PostgreSQL database in Kubernetes
# Usage: ./db-backup.sh [namespace]

NAMESPACE=${1:-endpoint-stats}
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/postgres-backup-${TIMESTAMP}.sql"

# Create backups directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Get the PostgreSQL pod name
POSTGRES_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o name | head -1 | sed 's/pod\///')

if [ -z "$POSTGRES_POD" ]; then
  echo "Error: No PostgreSQL pod found in namespace $NAMESPACE"
  exit 1
fi

echo "Creating backup of PostgreSQL database from pod $POSTGRES_POD..."

# Execute pg_dump inside the pod to create a backup
kubectl exec -n $NAMESPACE $POSTGRES_POD -- bash -c "PGPASSWORD=postgres pg_dump -U postgres postgres" > $BACKUP_FILE

if [ $? -eq 0 ]; then
  echo "Backup completed successfully. Saved to $BACKUP_FILE"
  echo "Backup size: $(du -h $BACKUP_FILE | cut -f1)"
else
  echo "Error: Backup failed"
  rm -f $BACKUP_FILE
  exit 1
fi
