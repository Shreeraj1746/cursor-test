#!/bin/bash
# Script to deploy a new version of the application
# Usage: ./deploy.sh <version> <namespace> <deployment-name>

VERSION=$1
NAMESPACE=$2
DEPLOYMENT=$3

# Validate input
if [ -z "$VERSION" ] || [ -z "$NAMESPACE" ] || [ -z "$DEPLOYMENT" ]; then
  echo "Error: Missing required parameters"
  echo "Usage: ./deploy.sh <version> <namespace> <deployment-name>"
  exit 1
fi

# Check if deployment exists
kubectl get deployment $DEPLOYMENT -n $NAMESPACE &> /dev/null
if [ $? -ne 0 ]; then
  echo "Error: Deployment $DEPLOYMENT not found in namespace $NAMESPACE"
  exit 1
fi

# Get current image name without version
CURRENT_IMAGE=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' | sed 's/:.*//')

# Set new image with the specified version
NEW_IMAGE="${CURRENT_IMAGE}:${VERSION}"

echo "Deploying new version of $DEPLOYMENT in namespace $NAMESPACE"
echo "Updating image from $(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}') to $NEW_IMAGE"

# Update the deployment with the new image
kubectl set image deployment/$DEPLOYMENT -n $NAMESPACE $DEPLOYMENT=$NEW_IMAGE

# Verify the rollout
echo "Verifying rollout..."
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

# Display pod status after rollout
echo "Deployment complete. Current pods:"
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT
