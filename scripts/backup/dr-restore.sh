#!/bin/bash
# Script to restore PostgreSQL database from backup in Kubernetes
# Usage: ./dr-restore.sh <backup-file> [namespace] [timeout]

# Parameters
BACKUP_FILE=${1}
NAMESPACE=${2:-endpoint-stats}
TIMEOUT=${3:-180s}

# Check if backup file was provided
if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found or not specified."
  echo "Usage: $0 <backup-file> [namespace] [timeout]"
  echo "Example: $0 ./backup-20250418.sql endpoint-stats 120s"
  exit 1
fi

# Get the PostgreSQL pod name
POSTGRES_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o name | head -1)
if [ -z "$POSTGRES_POD" ]; then
  echo "Error: No PostgreSQL pod found in namespace $NAMESPACE."
  exit 1
fi

echo "Using PostgreSQL pod: $POSTGRES_POD"
echo "Using backup file: $BACKUP_FILE"

# Copy the backup file to the pod
echo "Copying backup file to PostgreSQL pod..."
kubectl cp "$BACKUP_FILE" "$NAMESPACE/${POSTGRES_POD#*/}:/tmp/restore.sql" || {
  echo "Error: Failed to copy backup file to PostgreSQL pod."
  exit 1
}

# Restore the database
echo "Restoring database from backup..."
kubectl exec -n $NAMESPACE ${POSTGRES_POD} -- bash -c "PGPASSWORD=postgres psql -U postgres -d postgres -f /tmp/restore.sql" || {
  echo "Error: Failed to restore database from backup."
  exit 1
}

echo "Database restore completed successfully."

# Verify database restoration
echo "Verifying database restoration..."
kubectl exec -n $NAMESPACE ${POSTGRES_POD} -- bash -c "PGPASSWORD=postgres psql -U postgres -d postgres -c 'SELECT count(*) FROM information_schema.tables WHERE table_schema = '\''public'\'';'" || {
  echo "Warning: Could not verify database restoration. Please check manually."
}

echo "Disaster recovery process completed."
