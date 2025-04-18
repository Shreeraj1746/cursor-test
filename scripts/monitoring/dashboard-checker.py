#!/usr/bin/env python3
# ruff: noqa: TRY300
"""
Dashboard Checker Script.

This script checks if a dashboard exists in Grafana and creates it if not found.
It uses the Grafana API to perform these operations.
"""

import json
import logging
import os
import sys
from pathlib import Path
from typing import Any

import requests

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

# Configuration
GRAFANA_URL = "http://localhost:3000"
GRAFANA_USER = "admin"
# Get password from environment or use default (only for development)
GRAFANA_PASSWORD = os.environ.get("GRAFANA_PASSWORD", "admin")
DASHBOARD_UID = "endpoint-stats"
# Use absolute path for dashboard JSON file
DASHBOARD_JSON_FILE = Path(__file__).parent.parent / "create-dashboard.json"


def check_grafana_connection() -> bool:
    """Test connection to Grafana.

    Returns:
        bool: True if connection is successful, False otherwise.
    """
    logger.info("Checking connection to Grafana...")
    try:
        response = requests.get(f"{GRAFANA_URL}/api/health", timeout=10)
        if response.status_code == 200:
            logger.info("Successfully connected to Grafana.")
            return True
        logger.error(
            "Cannot connect to Grafana at %s (HTTP %s)",
            GRAFANA_URL,
            response.status_code,
        )
        return False
    except requests.RequestException:
        logger.exception("Error connecting to Grafana")
        return False


def get_auth_token() -> tuple[str, dict[str, Any] | None]:
    """Get authentication token or set up basic auth for Grafana API.

    Returns:
        tuple[str, dict[str, Any] | None]: Auth header and token response
    """
    logger.info("Authenticating with Grafana...")
    auth = (GRAFANA_USER, GRAFANA_PASSWORD)

    # Try to get an API token
    try:
        token_response = requests.post(
            f"{GRAFANA_URL}/api/auth/keys",
            json={"name": "dashboard-checker", "role": "Admin"},
            auth=auth,
            timeout=10,
        )

        if token_response.status_code == 200:
            token_data = token_response.json()

            if "key" in token_data:
                logger.info("Using token authentication...")
                return f"Bearer {token_data['key']}", token_data

        logger.info("Using basic authentication instead of token...")
        return "", None

    except requests.RequestException:
        logger.info("Using basic authentication instead of token...")
        return "", None


def check_dashboard_exists(auth_header: str) -> bool:
    """Check if the dashboard with specified UID exists.

    Args:
        auth_header: Authorization header value for API requests

    Returns:
        bool: True if dashboard exists, False otherwise
    """
    logger.info("Checking if dashboard exists...")

    headers = {}
    auth = None

    if auth_header:
        headers["Authorization"] = auth_header
    else:
        auth = (GRAFANA_USER, GRAFANA_PASSWORD)

    try:
        response = requests.get(
            f"{GRAFANA_URL}/api/dashboards/uid/{DASHBOARD_UID}",
            headers=headers,
            auth=auth,
            timeout=10,
        )

        if response.status_code == 200:
            logger.info("Dashboard 'Endpoint Statistics Dashboard' already exists!")
            logger.info("Dashboard info successfully retrieved.")
            return True

        logger.info("Dashboard not found (HTTP %s).", response.status_code)
        return False

    except requests.RequestException:
        logger.exception("Error checking dashboard")
        return False


def create_dashboard(auth_header: str) -> bool:
    """Create a new dashboard from the local JSON file.

    Args:
        auth_header: Authorization header value for API requests

    Returns:
        bool: True if dashboard was created successfully, False otherwise
    """
    logger.info("Creating dashboard...")

    # Check for the dashboard JSON file
    if not DASHBOARD_JSON_FILE.is_file():
        logger.error("Error: Dashboard JSON file '%s' not found!", DASHBOARD_JSON_FILE)
        return False

    logger.info("Using local dashboard JSON file: %s", DASHBOARD_JSON_FILE)

    # Read the dashboard JSON
    try:
        dashboard_data = json.loads(DASHBOARD_JSON_FILE.read_text())
    except (OSError, json.JSONDecodeError):
        logger.exception("Error reading dashboard JSON file")
        return False

    # Set up request headers and auth
    headers = {"Content-Type": "application/json"}
    auth = None

    if auth_header:
        headers["Authorization"] = auth_header
    else:
        auth = (GRAFANA_USER, GRAFANA_PASSWORD)

    # Create the dashboard
    try:
        response = requests.post(
            f"{GRAFANA_URL}/api/dashboards/db",
            json=dashboard_data,
            headers=headers,
            auth=auth,
            timeout=10,
        )

        if response.status_code == 200:
            data = response.json()

            if data.get("status") == "success":
                logger.info("Dashboard created successfully!")
                logger.info("Dashboard UID: %s", data.get("uid", "unknown"))
                logger.info("Dashboard URL: %s", data.get("url", "unknown"))
                return True

            logger.error("Failed to create dashboard:")
            logger.error("%s", response.text)
            return False

        logger.error("Failed to create dashboard:")
        logger.error("%s", response.text)
        return False

    except requests.RequestException:
        logger.exception("Error creating dashboard")
        return False


def revoke_api_key(auth_header: str, token_data: dict[str, Any]) -> bool:
    """Revoke the temporary API key.

    Args:
        auth_header: Authorization header value for API requests
        token_data: The token data from the creation response

    Returns:
        bool: True if key was revoked successfully, False otherwise
    """
    if not token_data or "id" not in token_data:
        return False

    logger.info("Revoking temporary API key...")

    headers = {}
    auth = None

    if auth_header:
        headers["Authorization"] = auth_header
    else:
        auth = (GRAFANA_USER, GRAFANA_PASSWORD)

    try:
        response = requests.delete(
            f"{GRAFANA_URL}/api/auth/keys/{token_data['id']}",
            headers=headers,
            auth=auth,
            timeout=10,
        )
        return response.status_code == 200

    except requests.RequestException:
        return False


def main() -> int:
    """Main function to run the dashboard checker.

    Returns:
        int: Exit code (0 for success, 1 for failure)
    """
    # Check connection to Grafana
    if not check_grafana_connection():
        return 1

    # Get authentication
    auth_header, token_data = get_auth_token()

    # Check if dashboard exists, create if not
    if check_dashboard_exists(auth_header):
        if token_data:
            revoke_api_key(auth_header, token_data)
        logger.info("Done.")
        return 0

    # Create dashboard if it doesn't exist
    if not create_dashboard(auth_header):
        if token_data:
            revoke_api_key(auth_header, token_data)
        return 1

    # Revoke API key if we created one
    if token_data:
        revoke_api_key(auth_header, token_data)

    logger.info("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
