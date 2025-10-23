-- Initialize PostgreSQL extensions
-- This script runs automatically via docker-entrypoint-initdb.d
-- Extensions are created as superuser before any migrations run

-- Enable pg_stat_statements for query performance monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
COMMENT ON EXTENSION pg_stat_statements IS 'Track planning and execution statistics of all SQL statements';

-- Enable pg_cron for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;
COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';

-- Enable pg_partman for partition management
-- Create in dedicated partman schema as per best practices
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;
COMMENT ON EXTENSION pg_partman IS 'Partition management for PostgreSQL';
