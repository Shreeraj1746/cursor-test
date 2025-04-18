# Project Reorganization Plan

## 1. Current State

The project has a generally well-organized structure with most Kubernetes configurations properly organized in the `k8s/` directory and its subdirectories. However, there are a few issues to address:

1. There are discrepancies between file paths referenced in the Runbook and the actual file locations
2. Some scripts may be unused or redundant
3. The directory structure could be improved for clarity and maintainability

## 2. K8s Directory Structure

The current `k8s/` directory has subdirectories for specific components:
- `cache/` - Redis cache configurations
- `core/` - Core application components like Flask API and namespace
- `database/` - PostgreSQL database configurations
- `deployment-strategy/` - Deployment configuration for rollouts, scaling, etc.
- `maintenance/` - Maintenance tasks, backup jobs, etc.
- `monitoring/` - Prometheus, Grafana, and other monitoring tools
- `networking/` - Ingress and service configurations
- `security/` - RBAC, network policies, and secrets
- `storage/` - Persistent volume configurations

This structure is good, but the Runbook refers to files at the root of the `k8s/` directory, creating potential confusion.

## 3. Scripts Organization

The `scripts/` directory contains several operational scripts:
- `dashboard-checker.py` - Sets up Grafana dashboards
- `db-backup.sh` - Database backup script
- `deploy.sh` - Deployment script
- `dr-restore.sh` - Disaster recovery restore script
- `health-check.sh` - Health check script
- `rollback.sh` - Rollback script for deployments

Some of these scripts may be unused or could be better organized.

## 4. Reorganization Plan

### 4.1 Align Kubernetes Configurations

Create symlinks from the root of the `k8s/` directory to the actual files to maintain compatibility with the Runbook:

```bash
# Create symlinks for commonly referenced files
ln -s k8s/core/namespace.yaml k8s/namespace.yaml
ln -s k8s/storage/persistent-volumes.yaml k8s/persistent-volumes.yaml
ln -s k8s/security/secrets.yaml k8s/secrets.yaml
ln -s k8s/database/postgres.yaml k8s/postgres.yaml
ln -s k8s/cache/redis.yaml k8s/redis.yml
ln -s k8s/core/flask-api.yaml k8s/flask-api.yaml
ln -s k8s/networking/ingress.yaml k8s/ingress.yaml
```

This will allow the Runbook commands to work as-is while maintaining a clean directory structure.

### 4.2 Scripts Organization

1. Categorize scripts by function:
   - Create a `scripts/deployment/` directory for deployment-related scripts
   - Create a `scripts/monitoring/` directory for monitoring-related scripts
   - Create a `scripts/backup/` directory for backup-related scripts (renaming the existing `backups/` to avoid confusion)

2. Move scripts to appropriate directories:
   - Move `deploy.sh` and `rollback.sh` to `scripts/deployment/`
   - Move `dashboard-checker.py` to `scripts/monitoring/`
   - Move `db-backup.sh` and `dr-restore.sh` to `scripts/backup/`
   - Keep `health-check.sh` at the root of `scripts/` as it's a general-purpose utility

3. Update script references in `Runbook.md` to reflect the new locations.

### 4.3 Documentation Updates

1. Create a project structure document that clearly explains the organization of the project, including:
   - The purpose of each directory
   - How the various components interact
   - Where to find specific configurations

2. Update the main README.md to include information about the project structure and how to navigate it.

### 4.4 Additional Improvements

1. Create a `.env.example` file to show required environment variables
2. Add a `CONTRIBUTING.md` file with guidelines for contributors
3. Add a simple `Makefile` with common operations for easy execution
4. Create a `scripts/setup.sh` script to help new developers set up the project

## 5. Implementation Plan

1. Create new directories
2. Move files to appropriate directories
3. Create symlinks for Runbook compatibility
4. Update documentation
5. Test all scripts and commands to ensure they still work
6. Clean up any remaining unused files

This plan will improve the organization of the project while maintaining compatibility with existing documentation and workflows.
