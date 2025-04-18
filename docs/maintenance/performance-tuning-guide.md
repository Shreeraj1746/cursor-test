# Performance Tuning Guide for Endpoint Statistics

## Resource Allocation Guidelines

### Flask API
- Start with 100m CPU, 128Mi memory per pod
- For every 100 req/s, add approximately 50m CPU
- For heavy statistical analysis workloads, increase memory to 256Mi per pod
- Optimal pod count: 3-5 for typical workloads

### PostgreSQL
- For databases under 10GB: 500m CPU, 1Gi memory
- For databases 10-50GB: 1000m CPU, 2Gi memory
- For databases over 50GB: 2000m CPU, 4Gi memory
- Consider read replicas for heavy read workloads

### Redis
- For caching only: 100m CPU, 256Mi memory
- With persistent storage: 200m CPU, 512Mi memory
- Consider Redis Cluster for datasets > 2GB

## Query Optimization

### Common Slow Queries and Solutions
1. Endpoint statistics aggregation:
   ```sql
   -- Original slow query
   SELECT endpoint, COUNT(*), AVG(response_time)
   FROM requests
   WHERE timestamp > NOW() - INTERVAL '30 days'
   GROUP BY endpoint;

   -- Optimized query
   SELECT endpoint, COUNT(*), AVG(response_time)
   FROM requests
   WHERE timestamp > NOW() - INTERVAL '30 days'
   GROUP BY endpoint
   ORDER BY COUNT(*) DESC
   LIMIT 10;
   ```

2. Add appropriate indices:
   ```sql
   CREATE INDEX idx_requests_timestamp ON requests(timestamp);
   CREATE INDEX idx_requests_endpoint ON requests(endpoint);
   CREATE INDEX idx_requests_endpoint_timestamp ON requests(endpoint, timestamp);
   ```

3. Pre-aggregate commonly accessed statistics in a materialized view:
   ```sql
   CREATE MATERIALIZED VIEW endpoint_daily_stats AS
   SELECT
     endpoint,
     DATE_TRUNC('day', timestamp) AS day,
     COUNT(*) AS request_count,
     AVG(response_time) AS avg_response_time,
     MAX(response_time) AS max_response_time,
     MIN(response_time) AS min_response_time,
     SUM(CASE WHEN status >= 500 THEN 1 ELSE 0 END) AS error_count
   FROM requests
   GROUP BY endpoint, DATE_TRUNC('day', timestamp);

   CREATE INDEX idx_endpoint_daily_stats_endpoint ON endpoint_daily_stats(endpoint);
   CREATE INDEX idx_endpoint_daily_stats_day ON endpoint_daily_stats(day);
   ```

4. Update materialized view periodically:
   ```sql
   REFRESH MATERIALIZED VIEW endpoint_daily_stats;
   ```

## Scaling Guidelines

- Set HPA targets at 70% CPU to allow buffer for traffic spikes
- Implement PodDisruptionBudgets for critical components
- Pre-scale before expected high-traffic events
- Use node anti-affinity to spread pods across nodes

## Caching Strategy

1. Use Redis for API-level caching with appropriate TTLs:
   - High-change data: 1-5 minutes
   - Medium-change data: 30-60 minutes
   - Reference data: 12-24 hours

2. Implement HTTP caching headers for client-side caching:
   ```python
   @app.route('/api/endpoint-stats/<endpoint_id>')
   def get_endpoint_stats(endpoint_id):
       # ... fetch data ...
       response = jsonify(stats)
       response.cache_control.max_age = 300  # 5 minutes
       response.cache_control.public = True
       return response
   ```

## Connection Pooling

- Database connections: Min 5, Max 20 per pod
- Redis connections: Min 2, Max 10 per pod
- Example database connection pool configuration:
  ```python
  db_pool = sqlalchemy.create_engine(
      'postgresql://admin:password@postgres/endpoint_stats',
      pool_size=10,
      max_overflow=10,
      pool_timeout=30,
      pool_recycle=1800
  )
  ```

## Network Optimization

- Use keepalive connections between components
- Configure appropriate timeouts
- Consider using a service mesh for advanced traffic management

## Regular Maintenance Tasks

1. Database:
   - VACUUM ANALYZE: Weekly
   - REINDEX: Monthly
   - Update statistics: Daily

2. Application:
   - Log rotation: Daily
   - Cache cleanup: Daily
   - Temporary file cleanup: Daily
