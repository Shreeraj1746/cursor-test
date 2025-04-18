# Endpoint Statistics Application Makefile
# A collection of useful commands for development and operations

.PHONY: setup setup-dev setup-k8s deploy-all test-all health-check backup-db restore-db clean help

# Default target
help:
	@echo "Endpoint Statistics Application Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  setup       - Set up both development and Kubernetes environments"
	@echo "  setup-dev   - Set up development environment"
	@echo "  setup-k8s   - Set up Kubernetes environment"
	@echo "  deploy-all  - Deploy all components to Kubernetes"
	@echo "  test-all    - Run all tests"
	@echo "  health-check - Run health check"
	@echo "  backup-db   - Backup the database"
	@echo "  restore-db  - Restore the database from backup"
	@echo "  clean       - Clean up all resources"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Example: make deploy-all"

# Setup targets
setup: setup-dev setup-k8s

setup-dev:
	@echo "Setting up development environment..."
	./scripts/setup.sh dev

setup-k8s:
	@echo "Setting up Kubernetes environment..."
	./scripts/setup.sh k8s

# Deployment targets
deploy-all:
	@echo "Deploying all components..."
	kubectl apply -f k8s/core/namespace.yaml
	kubectl apply -f k8s/storage/persistent-volumes.yaml
	kubectl apply -f k8s/security/secrets.yaml
	kubectl apply -f k8s/database/postgres.yaml
	kubectl apply -f k8s/cache/redis.yaml
	kubectl apply -f k8s/core/flask-api.yaml
	kubectl apply -f k8s/networking/ingress.yaml
	kubectl apply -f k8s/monitoring/
	@echo "Deployment complete."

# Testing targets
test-all:
	@echo "Running all tests..."
	pytest -xvs
	@echo "Testing complete."

# Operations targets
health-check:
	@echo "Running health check..."
	./scripts/health-check.sh health-report.txt
	@echo "Health check complete. See health-report.txt for results."

backup-db:
	@echo "Backing up database..."
	./scripts/backup/db-backup.sh
	@echo "Backup complete."

restore-db:
	@echo "Restoring database from backup..."
	@read -p "Enter backup file path: " BACKUP_FILE; \
	./scripts/backup/dr-restore.sh $$BACKUP_FILE
	@echo "Restore complete."

# Cleanup target
clean:
	@echo "Cleaning up resources..."
	kubectl delete -f k8s/core/flask-api.yaml || true
	kubectl delete -f k8s/cache/redis.yaml || true
	kubectl delete -f k8s/database/postgres.yaml || true
	kubectl delete -f k8s/monitoring/ || true
	kubectl delete -f k8s/networking/ingress.yaml || true
	kubectl delete -f k8s/security/secrets.yaml || true
	kubectl delete pvc -n endpoint-stats --all || true
	kubectl delete -f k8s/storage/persistent-volumes.yaml || true
	kubectl delete -f k8s/core/namespace.yaml || true
	@echo "Cleanup complete."
