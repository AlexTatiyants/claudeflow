---
description: Manage Docker environment for current feature
argument-hint: [start|stop|restart|logs|ps|down]
---

Manage Docker environment for feature: $ARGUMENTS

## Commands

- `start` - Start Docker containers for this feature
- `stop` - Stop Docker containers (preserves data)
- `restart` - Restart Docker containers
- `seed` - Copy database from main to this feature
- `logs` - Show container logs
- `ps` - Show running containers
- `ports` - Show assigned ports for this feature
- `down` - Stop and remove containers (cleanup)

If no argument, defaults to `start`.

## How It Works

### Port Assignment Strategy

Each worktree gets unique ports to avoid conflicts:

**Calculation:**
- Base ports from main `docker-compose.yml`
- Port offset = hash of feature name % 50 (range: 0-49)
- Actual port = base_port + offset

**Example:**
- Main app runs on: 3000, 5432, 6379
- Feature "dark-mode" (hash → offset 7):
  - App: 3007
  - DB: 5439
  - Redis: 6386
- Feature "email-notifications" (hash → offset 23):
  - App: 3023
  - DB: 5455
  - Redis: 6402

### Docker Compose Override

Main project has standard ports in `docker-compose.yml`:
```yaml
version: '3.8'

services:
  app:
    ports:
      - "3000:3000"  # Standard port in main
    environment:
      - PORT=3000
  
  db:
    ports:
      - "5432:5432"  # Standard port in main
  
  redis:
    ports:
      - "6379:6379"  # Standard port in main
```

Worktree creates `docker-compose.override.yml` that **replaces** ports:
```yaml
version: '3.8'

services:
  app:
    ports:
      - "${APP_PORT}:3000"  # Overrides main's port
    environment:
      - PORT=${APP_PORT}
      - FEATURE_NAME=${FEATURE_NAME}
  
  db:
    ports:
      - "${DB_PORT}:5432"  # Overrides main's port
  
  redis:
    ports:
      - "${REDIS_PORT}:6379"  # Overrides main's port
```

And `.env.docker` with calculated ports:
```
FEATURE_NAME=dark-mode
APP_PORT=3007
DB_PORT=5439
REDIS_PORT=6386
```

This way:
- **Main runs normally** with standard ports (3000, 5432, 6379)
- **Worktrees override** with unique ports (3007, 5439, 6386)
- No interference between main and worktrees

## Workflow

### 1. Generate Docker override files

On first run:
- Calculate port offset from feature name
- Create `docker-compose.override.yml`
- Create `.env.docker` with ports
- Show assigned ports to user

### 2. Start containers

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.yml --env-file .env.docker up -d
```

### 3. Seed database (optional but recommended)

After starting containers, seed from main:
```bash
/feature-docker seed
```

This copies data from main's database so you start with realistic test data:
- User accounts
- Reference data
- Sample content
- Configuration

### 4. Display info

```
✓ Docker containers started for feature: dark-mode

Access your app at:
  App:   http://localhost:3007
  DB:    localhost:5439
  Redis: localhost:6386

Database is empty. To seed from main:
  /feature-docker seed

To view logs:  /feature-docker logs
To stop:       /feature-docker stop
To cleanup:    /feature-docker down
```

## Port Collision Handling

If calculated port is already in use:
1. Try next port (+1, +2, +3...)
2. Max 10 attempts
3. Show error if all ports in range are taken

Keep a registry in main's `.docker-ports.json`:
```json
{
  "dark-mode": {
    "app": 3007,
    "db": 5439,
    "redis": 6386
  },
  "email-notifications": {
    "app": 3023,
    "db": 5455,
    "redis": 6402
  }
}
```

## Commands Implementation

### start
```bash
# Generate override files if needed
# docker-compose up -d
# Show access URLs
```

### stop
```bash
# docker-compose stop
# Containers stopped, data preserved
```

### restart
```bash
# docker-compose restart
```

### seed
```bash
# Seed feature database from main development database
# This copies data so you start with realistic test data

# Process:
# 1. Detect main database type (PostgreSQL, MySQL, MongoDB, etc.)
# 2. Get main database connection (port 5432 for standard setup)
# 3. Get feature database connection (port 5439 from .env.docker)
# 4. Dump from main, restore to feature

# PostgreSQL example:
pg_dump -h localhost -p 5432 -U dev -d myapp_dev --clean --if-exists | \
  psql -h localhost -p 5439 -U dev -d myapp_dev

# OR using docker-compose:
# In main directory
docker-compose exec db pg_dump -U dev myapp_dev > /tmp/db_dump.sql

# In feature worktree
docker-compose exec -T db psql -U dev myapp_dev < /tmp/db_dump.sql

# MySQL:
# mysqldump -h localhost -P 3306 -u dev myapp_dev | \
#   mysql -h localhost -P 3307 -u dev myapp_dev

# MongoDB:
# mongodump --host localhost:27017 --out /tmp/dump
# mongorestore --host localhost:27018 /tmp/dump

# Show result:
# ✓ Database seeded from main
# Tables copied: 25
# Approximate rows: 15,432
```

### logs
```bash
# docker-compose logs -f --tail=100
# Follow logs from all services
```

### ps
```bash
# docker-compose ps
# Show status of all containers
```

### down
```bash
# docker-compose down -v
# Stop and remove containers + volumes
# Warning: This removes data!
```

### ports
```bash
# Show assigned ports from .env.docker
```

## Multi-Service Support

Automatically detects services in `docker-compose.yml`:
- Web apps (3000+)
- Databases (5432+)
- Redis/cache (6379+)
- Other services (8000+)

Generates port mappings for all services found.

## Integration with Workflow

### In feature-prep
Add optional flag: `/feature-prep --docker` or `/feature-prep -d`
- Creates worktree
- Automatically runs `/feature-docker start`
- Shows ports in output

### In feature-build
Remind user: "Docker running at http://localhost:3007"

### In feature-end
Before merging:
- Stop Docker containers
- Optionally cleanup volumes

## Volume Management

Each feature can use:
- **Shared volumes** (symlinked from main) - for common data
- **Isolated volumes** (feature-specific) - for test data

Default strategy:
- Development DBs: isolated (each feature has own DB)
- File uploads: isolated (each feature has own uploads)
- Cache: isolated (independent Redis per feature)

## Environment Variables

Merge multiple env sources:
1. Main `.env` (symlinked)
2. `.env.docker` (generated, feature-specific)
3. Precedence: .env.docker overrides .env

## Database Migrations

Run migrations in isolated feature DB:
```bash
/feature-docker start
# Then run your project's migration command against the feature DB
```

## Testing Strategy

```bash
# Start feature environment
/feature-docker start

# Run your project's test suite against feature DB

# Cleanup test data
/feature-docker restart
```

## Resource Cleanup

Show warning if too many feature containers running:
```
⚠️ Warning: 5 feature environments are running
This may use significant resources (CPU/memory/disk)

Currently running:
- dark-mode (ports: 3007, 5439, 6386)
- email-notifications (ports: 3023, 5455, 6402)
- user-settings (ports: 3031, 5463, 6410)
- performance-improvements (ports: 3042, 5474, 6421)
- refactor-auth (ports: 3015, 5447, 6394)

To stop unused features:
1. Switch to feature worktree
2. Run: /feature-docker down
```

## Docker Compose Requirements

Expects base `docker-compose.yml` in main with:
- Service definitions
- Build context
- Base configuration
- **Standard ports** (will be overridden in worktrees)

Example main `docker-compose.yml`:
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"  # Standard port for main
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
  
  db:
    image: postgres:15
    ports:
      - "5432:5432"  # Standard port for main
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=dev
      - POSTGRES_PASSWORD=dev
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"  # Standard port for main
```

**Main project runs normally:**
```bash
# In main directory
docker-compose up
# → App on 3000, DB on 5432, Redis on 6379
```

**Worktrees override ports:**
```bash
# In worktree
/feature-docker start
# → App on 3007, DB on 5439, Redis on 6386 (no conflict!)
```

## Advanced: Custom Services

If feature needs additional services:
1. Edit `docker-compose.override.yml` in worktree
2. Add custom services with unique ports
3. Update `.env.docker` with new ports

Example: Feature needs Elasticsearch
```yaml
# In worktree's docker-compose.override.yml
services:
  elasticsearch:
    image: elasticsearch:8
    ports:
      - "${ELASTIC_PORT}:9200"
    environment:
      - discovery.type=single-node
```

## Error Handling

**Docker not running:**
```
Error: Docker daemon not running
Please start Docker Desktop and try again
```

**Port already in use:**
```
Error: Port 3007 is already in use
Trying alternative port: 3008...
✓ Using port 3008
```

**No docker-compose.yml in main:**
```
Error: No docker-compose.yml found in main project
This command requires a Docker Compose configuration
```

**Services failed to start:**
```
Error: Some services failed to start
Run: /feature-docker logs
To see error details
```

## Best Practices

1. **Stop unused containers** - Free up resources when not actively working
2. **Use `down` between major changes** - Clean slate for fresh testing
3. **Don't commit override files** - They're feature-specific (add to .gitignore)
4. **Check ports** - Run `/feature-docker ports` to see your URLs
5. **Monitor resources** - Use `docker stats` if system gets slow

## Files Created

In each worktree:
- `docker-compose.override.yml` - Port and feature-specific config
- `.env.docker` - Calculated ports and feature name
- `.docker-ports.lock` - Prevent port conflicts during start

Added to main (or `.gitignore`):
- `.docker-ports.json` - Global port registry

## Extensions
Check for `.claude/claudeflow-extensions/feature-docker.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.

## Important Notes

- Override files should NOT be committed (add `docker-compose.override.yml` to `.gitignore`)
- Each feature gets completely isolated environment
- Data is ephemeral by default (use `down` to clean up)
- Main `docker-compose.yml` has standard ports, worktrees override them
- Worktrees share Docker images (built once, used everywhere)
- Main project runs normally on standard ports (3000, 5432, etc.)
- No interference between main and worktree environments
