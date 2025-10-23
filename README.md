# PostgreSQL Image with Extensions

![Build](https://github.com/GunarsK-portfolio/postgres-image/workflows/Build%20and%20Publish%20Docker%20Image/badge.svg)

Custom PostgreSQL 18 Docker image with pre-installed extensions for the portfolio project.

## Included Extensions

- **pg_cron v1.6.7** - PostgreSQL job scheduler for running periodic tasks
- **pg_partman v5.3.0** - Partition management extension for automated table partitioning
- **pg_stat_statements** - Query performance monitoring (included in base postgres:18)

## Automatic Extension Initialization

This image includes an `init-extensions.sql` script in `/docker-entrypoint-initdb.d/` that automatically creates the extensions when the container starts for the first time. This means:

- ✅ Extensions are ready to use immediately
- ✅ No manual `CREATE EXTENSION` commands needed in most cases
- ✅ Works in both CI and production environments
- ⚠️ You still need to create database users and grant them permissions separately

## Usage

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/gunarsk-portfolio/postgres-image:latest
```

### Docker Compose

```yaml
services:
  postgres:
    image: ghcr.io/gunarsk-portfolio/postgres-image:latest
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      # Default PostgreSQL superuser
      POSTGRES_USER: ${POSTGRES_SUPERUSER}
      POSTGRES_PASSWORD: ${POSTGRES_SUPERUSER_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Docker Run

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_DB=portfolio \
  -p 5432:5432 \
  ghcr.io/gunarsk-portfolio/postgres-image:latest
```

### Verify Extensions

Extensions are created automatically on first startup. You can verify they're available:

```bash
docker exec -it postgres psql -U postgres -d portfolio -c "\dx"
```

Expected output:
```
                                      List of installed extensions
      Name       | Version |   Schema   |                        Description
-----------------+---------+------------+-----------------------------------------------------------
 pg_cron         | 1.6     | public     | Job scheduler for PostgreSQL
 pg_partman      | 5.3.0   | partman    | Extension to manage partitioned tables by time or ID
 pg_stat_statements | 1.10  | public     | track planning and execution statistics of all SQL
```

## Available Tags

- `latest` - Latest build from main branch
- `v1`, `v1.0`, `v1.0.0` - Semantic version tags
- `main` - Latest commit on main branch

## Building Locally

```bash
docker build -t postgres-image:local .
```

## Configuration

### pg_cron

This image pre-configures PostgreSQL with `shared_preload_libraries = 'pg_cron'`.

After creating the extension, you can schedule jobs:

```sql
-- Schedule a job to run every hour
SELECT cron.schedule('cleanup-job', '0 * * * *', 'DELETE FROM logs WHERE created_at < NOW() - INTERVAL ''30 days''');
```

### pg_partman

The extension is automatically created in the `partman` schema. Use it to manage table partitions:

```sql
-- Setup automatic partitioning for a table
SELECT partman.create_parent(
    p_parent_table := 'public.events',
    p_control := 'created_at',
    p_interval := '1 month',
    p_premake := 3
);
```

## CI/CD

This image is automatically built and published to GitHub Container Registry when:

- Code is pushed to the `main` branch
- A version tag (e.g., `v1.0.0`) is created
- A pull request is opened (build only, not published)

## Base Image

Built on top of the official [postgres:18-alpine](https://hub.docker.com/_/postgres) image for a smaller footprint.

## License

MIT
