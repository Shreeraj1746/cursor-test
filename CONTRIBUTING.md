# Contributing to Endpoint Statistics Application

Thank you for considering contributing to the Endpoint Statistics Application! This document outlines the process for contributing to this project.

## Table of Contents

- [Project Structure](#project-structure)
- [Development Environment Setup](#development-environment-setup)
- [Contribution Workflow](#contribution-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)
- [Submitting Changes](#submitting-changes)

## Project Structure

The project is organized as follows:
- `k8s/`: Kubernetes configuration files, organized by component
- `scripts/`: Operational scripts for deployment, monitoring, and maintenance
- `docs/`: Documentation files
- `tests/`: Test files

For a detailed overview of the project structure, see [docs/project_structure.md](docs/project_structure.md).

## Development Environment Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-organization/endpoint-stats.git
   cd endpoint-stats
   ```

2. Set up the development environment using the provided script:
   ```bash
   ./scripts/setup.sh dev
   ```

   This will:
   - Create a Python virtual environment
   - Install required dependencies
   - Set up pre-commit hooks

3. For Kubernetes development, set up the Kubernetes environment:
   ```bash
   ./scripts/setup.sh k8s
   ```

4. Alternatively, you can use the Makefile for setup:
   ```bash
   make setup-dev    # For development environment
   make setup-k8s    # For Kubernetes environment
   make setup        # For both environments
   ```

## Contribution Workflow

1. Create a new branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the coding standards described below

3. Test your changes using the appropriate test procedures

4. Commit your changes with a clear commit message:
   ```bash
   git commit -m "Feature: Brief description of your changes"
   ```

5. Push your branch to the repository:
   ```bash
   git push origin feature/your-feature-name
   ```

6. Create a pull request against the main branch

## Coding Standards

### Python Code

- Follow PEP 8 style guidelines
- Use type hints for all function parameters and return values
- Write docstrings in Google style format
- Use descriptive variable names
- Keep functions focused on a single responsibility
- Use the pre-commit hooks to ensure code quality

### Kubernetes Configuration

- Use YAML format for all Kubernetes configurations
- Place configurations in the appropriate subdirectory under `k8s/`
- Include resource limits and requests in all pod specifications
- Follow the naming conventions established in the project

### Shell Scripts

- Include a shebang line and a comment describing the script's purpose
- Check for required commands and exit gracefully if they're not available
- Provide help information with a `-h` or `--help` flag
- Use error handling and proper exit codes

## Testing Guidelines

- Write unit tests for all Python code
- Write integration tests for API endpoints
- Test Kubernetes configurations with `kubectl apply --dry-run=client`
- Use the health check script to verify deployments

To run tests:
```bash
# Run Python tests
make test-all

# Run health checks
make health-check
```

## Documentation Guidelines

- Update documentation when making significant changes
- Document all public functions, classes, and modules
- Update the Runbook.md file when changing deployment procedures
- Keep README.md up to date with current information

## Submitting Changes

1. Ensure all tests pass
2. Update documentation as necessary
3. Make sure your branch is up to date with the main branch
4. Submit a pull request with a clear description of the changes
5. Respond to review comments and make requested changes

Thank you for contributing to the Endpoint Statistics Application!
