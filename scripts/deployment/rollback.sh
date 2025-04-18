#!/bin/bash

# Parameters
DEPLOYMENT=${1}
NAMESPACE=${2:-default}
TIMEOUT=${3:-60s}

# Check if deployment name was provided
if [ -z "$DEPLOYMENT" ]; then
  echo "Usage: $0 <deployment-name> [namespace] [timeout]"
  echo "Example: $0 flask-api endpoint-stats 90s"
  exit 1
fi

echo "Current rollout history for $DEPLOYMENT:"
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE

echo "Rolling back $DEPLOYMENT to previous revision..."
kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE

echo "Verifying rollback..."
if kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=$TIMEOUT; then
  echo "Rollback successful."
  echo "Current deployment status:"
  kubectl get deployment $DEPLOYMENT -n $NAMESPACE
  echo "Current pods:"
  kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT
else
  echo "Rollback status check timed out after $TIMEOUT."
  echo "Checking current status manually:"
  kubectl get deployment $DEPLOYMENT -n $NAMESPACE
  kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT

  echo "Attempting to force rollback to a stable revision..."
  STABLE_REVISION=$(kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE | grep -v REVISION | awk 'NR==1 {print $1}')

  if [ -n "$STABLE_REVISION" ]; then
    echo "Forcing rollback to revision $STABLE_REVISION..."
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE --to-revision=$STABLE_REVISION
    echo "Current deployment status after forced rollback:"
    kubectl get deployment $DEPLOYMENT -n $NAMESPACE
    kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT
  else
    echo "Could not identify a stable revision. Manual intervention may be required."
  fi
fi
