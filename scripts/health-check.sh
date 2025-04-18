#!/bin/bash
# System Health Check Script
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
  # Use the kubectl port-forward and curl from the host instead of from inside the container
  echo "Checking API health via port-forward..." >> $OUTPUT_FILE
  # Check if we can reach the API health endpoint
  HEALTH_RESPONSE=$(curl -s http://localhost:9999/health 2>/dev/null)
  if [ -n "$HEALTH_RESPONSE" ]; then
    echo "$HEALTH_RESPONSE" >> $OUTPUT_FILE
  else
    echo "Could not access health endpoint through port-forward" >> $OUTPUT_FILE
  fi
else
  echo "No API pod found!" >> $OUTPUT_FILE
fi

# 5. Database checks
echo -e "\n## Database Health" >> $OUTPUT_FILE
DB_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o name | head -1)
if [ -n "$DB_POD" ]; then
  echo "Connection test:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $DB_POD -- bash -c "PGPASSWORD=postgres psql -U postgres -d postgres -c 'SELECT 1;'" >> $OUTPUT_FILE

  echo "Database size:" >> $OUTPUT_FILE
  # Use simpler query to get database size
  kubectl exec -n $NAMESPACE $DB_POD -- bash -c "PGPASSWORD=postgres psql -U postgres -d postgres -c 'SELECT pg_database_size(current_database())::text;'" >> $OUTPUT_FILE

  echo "Connection count:" >> $OUTPUT_FILE
  kubectl exec -n $NAMESPACE $DB_POD -- bash -c "PGPASSWORD=postgres psql -U postgres -d postgres -c 'SELECT count(*) FROM pg_stat_activity;'" >> $OUTPUT_FILE
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
