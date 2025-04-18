# Log Retention Policy

## Retention Periods

| Log Type       | Retention Period | Storage Location |
|---------------|------------------|------------------|
| Application   | 30 days          | Elasticsearch    |
| System        | 14 days          | Elasticsearch    |
| Security      | 365 days         | Secured storage  |
| Audit         | 180 days         | Secured storage  |
| Performance   | 7 days           | Elasticsearch    |

## Compliance Requirements

For regulated industries, adjust retention periods to:
- Financial services: Minimum 7 years for transaction logs
- Healthcare: Minimum 6 years for access logs
- PCI-DSS: Minimum 1 year for authentication logs

## Log Rotation Configuration

Logs will be rotated as follows:
- Size-based rotation: When log file reaches 100MB
- Time-based rotation: Daily at midnight

## Archival Procedure

1. Logs older than retention period are compressed
2. Compressed logs are moved to cold storage
3. Verification of archived logs is performed monthly

## Log Collection and Forwarding

- Application logs are collected via Fluentd agents
- System logs are collected via node-level logging agents
- All logs are forwarded to central Elasticsearch cluster
- Critical security events trigger real-time alerts

## Log Categories and Severity Levels

| Category | Examples | Minimum Severity to Store |
|----------|----------|--------------------------|
| Security | Authentication attempts, permission changes | INFO |
| Performance | API response times, resource usage | WARNING |
| Application | API requests, business logic | INFO |
| System | Node events, pod scheduling | WARNING |
| Audit | Data access, configuration changes | INFO |

## Log Format Standards

All logs should follow the structured JSON format:
```json
{
  "timestamp": "2025-04-18T14:32:15Z",
  "level": "INFO",
  "category": "application",
  "service": "flask-api",
  "message": "Request processed successfully",
  "context": {
    "request_id": "abc-123",
    "user_id": "user-456",
    "endpoint": "/api/stats"
  },
  "metrics": {
    "duration_ms": 45,
    "status_code": 200
  }
}
```
