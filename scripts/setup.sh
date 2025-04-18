#!/bin/bash
# Setup script for Endpoint Statistics Application
# This script helps new developers set up the project environment

# Exit on error
set -e

# Display help message
display_help() {
    echo "Endpoint Statistics Application Setup Script"
    echo ""
    echo "Usage: ./scripts/setup.sh [command]"
    echo ""
    echo "Commands:"
    echo "  dev         Setup development environment"
    echo "  k8s         Setup Kubernetes environment"
    echo "  all         Setup both development and Kubernetes environments"
    echo "  help        Display this help message"
    echo ""
    echo "Example: ./scripts/setup.sh dev"
}

# Setup development environment
setup_dev() {
    echo "Setting up development environment..."

    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        echo "Error: Python 3 is required but not installed."
        exit 1
    fi

    # Check Python version
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo "Found Python version: $PYTHON_VERSION"

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        echo "Creating virtual environment..."
        python3 -m venv venv
    else
        echo "Virtual environment already exists."
    fi

    # Activate virtual environment
    echo "Activating virtual environment..."
    source venv/bin/activate

    # Install dependencies
    echo "Installing dependencies..."
    pip install -r requirements.txt

    # Install development dependencies
    echo "Installing development dependencies..."
    pip install -r requirements-test.txt

    # Setup pre-commit hooks
    echo "Setting up pre-commit hooks..."
    pre-commit install

    echo "Development environment setup complete."
}

# Setup Kubernetes environment
setup_k8s() {
    echo "Setting up Kubernetes environment..."

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is required but not installed."
        echo "Please install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        exit 1
    fi

    # Check kubectl version
    KUBECTL_VERSION=$(kubectl version --client -o json | grep -o '"gitVersion": "[^"]*"' | head -1)
    echo "Found kubectl version: $KUBECTL_VERSION"

    # Check if a Kubernetes cluster is running
    if ! kubectl cluster-info &> /dev/null; then
        echo "Error: No Kubernetes cluster is running or kubectl is not configured correctly."
        echo "Please start a Kubernetes cluster (Minikube, Kind, Docker Desktop, etc.)"
        exit 1
    fi

    # Create namespace
    echo "Creating namespace..."
    kubectl apply -f k8s/core/namespace.yaml

    echo "Kubernetes environment setup complete."
    echo ""
    echo "To deploy the complete application, follow the instructions in the Runbook.md file."
}

# Main function
main() {
    # If no arguments provided, display help
    if [ $# -eq 0 ]; then
        display_help
        exit 0
    fi

    # Parse command
    case "$1" in
        "dev")
            setup_dev
            ;;
        "k8s")
            setup_k8s
            ;;
        "all")
            setup_dev
            setup_k8s
            ;;
        "help")
            display_help
            ;;
        *)
            echo "Error: Unknown command: $1"
            display_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
