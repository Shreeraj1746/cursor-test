# Endpoint Statistics Application: Docker to Kubernetes Learning Journey

This project serves as a comprehensive learning experience for transitioning from Docker to Kubernetes. It starts with a simple Flask application running in Docker and guides you through transforming it into a production-ready Kubernetes deployment with monitoring and observability tools.

## Table of Contents

- [Project Overview](#project-overview)
- [Learning Journey](#learning-journey)
  - [Part 1: Docker Basics](#part-1-docker-basics)
  - [Part 2: Kubernetes Implementation](#part-2-kubernetes-implementation)
- [Development Tools](#development-tools)
- [Using the Makefile](#using-the-makefile)
- [Project Structure](#project-structure)
- [Additional Resources](#additional-resources)
- [Getting Started](#getting-started)

## Project Overview

This is a Flask application that tracks endpoint access counts using PostgreSQL. While it's a simple application, it provides an excellent foundation for learning both Docker and Kubernetes concepts. The project now includes a complete Kubernetes infrastructure with monitoring components.

### Key Features

- Endpoint access tracking
- PostgreSQL data persistence
- Redis caching
- Grafana and Prometheus monitoring
- Python-based dashboard checker
- Comprehensive test suite
- Production-ready development tools
- Detailed Kubernetes implementation guide
- Persistent volumes and storage management

### Current Status

The project has been fully migrated from a Docker-only setup to a Kubernetes infrastructure with monitoring and observability tools. Key components include:

- Flask API deployed as a Kubernetes service
- PostgreSQL with persistent storage
- Redis for caching
- Grafana for visualization
- Prometheus for metrics collection
- Python utility for dashboard management
- Complete YAML configurations for all Kubernetes resources
- Step-by-step implementation documentation

### Recent Improvements

The project has undergone significant reorganization to improve maintainability and developer experience:

- **Enhanced File Organization**: Files are now logically grouped by function in their respective directories
- **Makefile Added**: Common operations simplified through a comprehensive Makefile
- **Improved Documentation**: Added detailed project structure documentation and contributor guidelines
- **Setup Script**: New developers can get started quickly with the `scripts/setup.sh` script
- **Environment Variables**: Added `.env.example` with sample configuration

## Learning Journey

### Part 1: Docker Basics

Start by understanding the application running in Docker. This phase helps you grasp container concepts and Docker Compose basics.

#### Prerequisites

- Docker and Docker Compose

#### Running the Application

1. Start the application and database:

```bash
docker compose up -d
```

2. Check the logs:

```bash
docker compose logs -f
```

3. Stop and clean up:

```bash
docker compose down
```

#### Testing

Run tests in a Docker container for consistent results:

```bash
# Run tests with normal output
docker compose run --rm web pytest -v

# Run tests with coverage report
docker compose run --rm web pytest -v --cov=app
```

#### Using the Application

The application runs on port 9999 and provides these endpoints:

- `GET http://localhost:9999/` - Welcome message and access count
- `GET http://localhost:9999/stats` - Access counts for all endpoints

Note: You may need to run port forwarding to access these urls from your host
```
kubectl port-forward -n endpoint-stats svc/flask-api 9999:9999
```

Example responses:

```json
// GET /
{
  "message": "Hello, World!",
  "access_count": 1
}

// GET /stats
{
  "stats": {
    "/": 1,
    "/stats": 1
  },
  "access_count": 1
}
```

### Part 2: Kubernetes Implementation

Once you're comfortable with the Docker setup, follow the comprehensive guides in the `docs/` directory to transform this application into a Kubernetes deployment.

#### Prerequisites for Kubernetes

- A local Kubernetes cluster (Minikube, Kind, or Docker Desktop Kubernetes)
- `kubectl` command-line tool
- Basic understanding of Docker and container concepts
- Familiarity with YAML syntax

#### Documentation Structure

The `docs/` directory contains detailed guides organized into five phases:

- `impl_phase1.md`: Basic Infrastructure Setup
- `impl_phase2.md`: Monitoring and Observability
- `impl_phase3.md`: Security Implementation
- `impl_phase4.md`: Deployment Strategy
- `impl_phase5.md`: Monitoring and Maintenance
- `implementation_checklist.md`: Consolidated checklist for tracking progress

#### Implemented Kubernetes Components

The project now includes the following Kubernetes resources:

- **Namespace**: Dedicated namespace for the application
- **Flask API**: Deployment and service for the main application
- **PostgreSQL**: StatefulSet with persistent volume claims
- **Redis**: Deployment and service for caching
- **Ingress**: Rules for external access
- **Secrets**: Secure storage for sensitive information
- **Monitoring Stack**:
  - Prometheus for metrics collection
  - Grafana for visualization and dashboards
  - ConfigMaps for configuration
  - Persistent volumes for data storage

#### Python Dashboard Checker

The project includes a Python utility (`scripts/dashboard-checker.py`) that:

1. Checks if a specific dashboard exists in Grafana
2. Creates the dashboard if it doesn't exist
3. Uses Grafana API to interact with the monitoring system
4. Implements proper error handling and logging

This tool is useful for ensuring that monitoring dashboards are properly set up when deploying the application.

#### Learning Approach

1. Start with Phase 1 to understand basic Kubernetes concepts
2. Follow each phase sequentially as they build upon each other
3. Use the implementation checklist to track your progress
4. Experiment with different configurations and observe their effects

#### Tips for Learning Kubernetes

1. **Hands-on Practice**:
   - Create a new namespace for your learning environment
   - Try different configurations and observe their effects
   - Use `kubectl describe` and `kubectl logs` to understand what's happening
   - Experiment with scaling, updates, and rollbacks

2. **Debugging Tips**:
   - Use `kubectl get events` to see what's happening in your cluster
   - Check pod logs with `kubectl logs <pod-name>`
   - Use `kubectl describe` to get detailed information about resources
   - Enable verbose logging with `kubectl --v=6` for more details

3. **Best Practices**:
   - Always use namespaces to isolate your learning environment
   - Clean up resources when you're done to avoid cluster clutter
   - Use `kubectl apply -f` instead of `kubectl create` for idempotency
   - Take notes on what works and what doesn't

4. **Common Pitfalls to Avoid**:
   - Don't forget to set resource limits
   - Always use health checks
   - Implement proper security contexts
   - Use secrets for sensitive data
   - Consider scalability in your design

## Development Tools

This project uses a comprehensive set of development tools to ensure code quality and consistency:

### Code Quality Tools

- **Ruff** (v0.3.3) - All-in-one Python linter and formatter
  - Code formatting (similar to Black)
  - Import sorting (similar to isort)
  - Code style checking (similar to flake8)
  - Static type checking (similar to mypy)
  - And many more checks!

### Testing Tools

- **pytest** (v8.0.2) - Testing framework
- **pytest-cov** (v4.1.0) - Test coverage
- **pytest-flask** (v1.3.0) - Flask testing utilities

### Utility Scripts

- **dashboard-checker.py** - Python script for managing Grafana dashboards:
  - Checks for existing dashboards
  - Creates dashboards from JSON templates
  - Handles authentication securely
  - Provides detailed logging
  - Uses best practices for error handling

To run the dashboard checker:

```bash
# Make sure Grafana is running
python scripts/dashboard-checker.py
```

### Git Hooks

- **pre-commit** (v3.6.2) - Git hook framework
- **commitizen** (v3.10.0) - Commit message formatting

To install the hooks:

```bash
pre-commit install  # Install pre-commit hooks
pre-commit install --hook-type pre-push  # Install pre-push hooks
```

### Using the Makefile

This project includes a comprehensive Makefile that simplifies common development and operational tasks. The Makefile provides a consistent interface for working with the project, regardless of whether you're in development or production.

#### Available Make Commands

| Command | Description |
|---------|-------------|
| `make help` | Display all available commands with descriptions |
| `make setup` | Set up both development and Kubernetes environments |
| `make setup-dev` | Set up development environment only |
| `make setup-k8s` | Set up Kubernetes environment only |
| `make deploy-all` | Deploy all components to Kubernetes |
| `make test-all` | Run all tests |
| `make health-check` | Run health check and generate report |
| `make backup-db` | Backup the database |
| `make restore-db` | Restore the database from backup |
| `make clean` | Clean up all resources |

#### Common Usage Examples

**Setting up your environment**:
```bash
# Complete setup (both dev and k8s)
make setup

# Just development environment
make setup-dev

# Just Kubernetes environment
make setup-k8s
```

**Deployment workflow**:
```bash
# Deploy all components
make deploy-all

# Verify deployment health
make health-check

# View the health report
cat health-report.txt
```

**Database operations**:
```bash
# Create a database backup
make backup-db

# Restore from a backup (you'll be prompted for the backup file)
make restore-db
```

**Cleanup**:
```bash
# Remove all deployed resources
make clean
```

#### Extending the Makefile

You can extend the Makefile with your own commands by adding new targets. For example, to add a new target for running a specific test:

```makefile
test-specific:
	@echo "Running specific test..."
	pytest -xvs tests/test_specific.py
```

Then you can run:
```bash
make test-specific
```

For more details on the project structure and organization, refer to the [Project Structure Documentation](docs/project_structure.md).

### Pre-commit Checks

The following checks are performed automatically before each commit:

- Code formatting and linting (Ruff)
- YAML validation
- JSON validation
- Merge conflict detection
- Private key detection
- Commit message formatting (commitizen)

Additionally, all unit tests are automatically run in Docker before each push to ensure code quality. The hook ensures that:

1. The database container is up and running
2. The web service is built with the latest changes
3. All tests pass with coverage report

### Running Code Quality Checks

You can run Ruff manually to check and fix code quality issues:

```bash
# Check code quality
docker compose run --rm web ruff check .

# Fix issues automatically
docker compose run --rm web ruff check . --fix

# Format code
docker compose run --rm web ruff format .
```

To run all pre-commit checks in Docker:

```bash
docker compose run --rm web pre-commit run --all-files
```

## Project Structure

The project has been reorganized to improve maintainability and clarity. The structure is now:

- `app.py` - Main Flask application with endpoint tracking
- `requirements.txt` - Python dependencies
- `requirements-test.txt` - Test dependencies
- `Dockerfile` - Docker configuration
- `docker-compose.yml` - Docker Compose configuration
- `Makefile` - Common operations for development and deployment
- `.env.example` - Example environment variables
- `CONTRIBUTING.md` - Guidelines for contributors
- `k8s/` - Kubernetes YAML configurations organized by component
  - `core/` - Core application components (namespace, Flask API)
  - `database/` - Database configurations
  - `cache/` - Redis cache configurations
  - `storage/` - Persistent storage configurations
  - `networking/` - Ingress and service configurations
  - `security/` - RBAC, network policies, and secrets
  - `monitoring/` - Monitoring stack configurations
  - `deployment-strategy/` - Deployment configuration for rollouts, scaling
  - `maintenance/` - Maintenance tasks, backup jobs, etc.
- `scripts/` - Operational scripts organized by function
  - `deployment/` - Deployment and rollback scripts
  - `backup/` - Backup and restore scripts
  - `monitoring/` - Monitoring configuration scripts
  - `health-check.sh` - Health check utility
  - `setup.sh` - Environment setup script
- `tests/` - Test files
- `docs/` - Kubernetes implementation guides and documentation
  - `project_structure.md` - Detailed project structure documentation

For a more detailed explanation of the project structure, please see [docs/project_structure.md](docs/project_structure.md).

### Deploying with the Makefile

The entire deployment process described in the "Deploying the Complete Application" section below can now be simplified to:

```bash
# Set up Kubernetes environment
make setup-k8s

# Deploy all components
make deploy-all

# Verify deployment
make health-check
```

## Additional Resources

### Kubernetes Learning Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

### Project Notes

- The application uses PostgreSQL 15 for storing endpoint access counts
- The database is configured with health checks to ensure proper startup order
- All dependencies are managed through Docker, no local Python installation required
- Pre-commit hooks ensure consistent code quality and formatting
- The project uses conventional commits for commit messages
- Monitoring is implemented with Prometheus and Grafana
- Python dashboard checker ensures Grafana dashboards are correctly set up

## Getting Started

### Starting from the Beginning

If you want to start this tutorial from the beginning without any of the generated Kubernetes infrastructure components, you can checkout the checkpoint branch:

```bash
git checkout checkpoint-2025-04-26
```

This branch represents the initial state of the project with only the Docker setup and without any Kubernetes components or Python utilities.

### Deploying the Complete Application

The recommended way to deploy the complete application is using the Makefile:

```bash
# Set up Kubernetes environment
make setup-k8s

# Deploy all components
make deploy-all
```

If you prefer to deploy components individually, you can use these commands:

1. Ensure you have a working Kubernetes cluster (Minikube, Kind, or Docker Desktop Kubernetes)

2. Create the namespace:
   ```bash
   kubectl apply -f k8s/core/namespace.yaml
   ```

3. Deploy the persistent volumes:
   ```bash
   kubectl apply -f k8s/storage/persistent-volumes.yaml
   ```

4. Deploy the secrets:
   ```bash
   kubectl apply -f k8s/security/secrets.yaml
   ```

5. Deploy the database:
   ```bash
   kubectl apply -f k8s/database/postgres.yaml
   ```

6. Deploy Redis:
   ```bash
   kubectl apply -f k8s/cache/redis.yaml
   ```

7. Deploy the Flask API:
   ```bash
   kubectl apply -f k8s/core/flask-api.yaml
   ```

8. Deploy the monitoring stack:
   ```bash
   kubectl apply -f k8s/monitoring/
   ```

9. Deploy the ingress rules:
   ```bash
   kubectl apply -f k8s/networking/ingress.yaml
   ```

10. Verify the dashboard is properly set up:
    ```bash
    python scripts/monitoring/dashboard-checker.py
    ```

Once deployment is complete, run a health check:

```bash
make health-check
# or manually:
./scripts/health-check.sh health-report.txt
```

### Exploring the Monitoring Stack

Once the application is deployed, you can access:

- The Flask API at the ingress endpoint
- Grafana at http://localhost:3000 (default credentials: admin/admin)
- Prometheus at http://localhost:9090

Note: You may need to run port forwarding to access these urls from your host
```
kubectl port-forward -n endpoint-stats svc/grafana 3000:3000
kubectl port-forward -n endpoint-stats svc/prometheus 9090:9090
```

Remember: This project is designed as a learning journey from Docker to Kubernetes. Take your time to understand each concept before moving to the next phase. The documentation in the `docs/` directory is designed to guide you through this journey step by step.
