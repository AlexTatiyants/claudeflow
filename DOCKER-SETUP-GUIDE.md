# Docker Setup Guide for Feature Workflow

Complete guide to setting up and using isolated Docker environments for each feature.

## Overview

The feature workflow supports running each feature in its own isolated Docker environment:
- ✅ Each feature gets unique ports (no conflicts)
- ✅ Isolated databases, caches, and services
- ✅ Test multiple features simultaneously
- ✅ Easy to reset and cleanup
- ✅ Consistent with main environment

## Prerequisites

1. **Docker Desktop** installed and running
2. **docker-compose** command available
3. **Base docker-compose.yml** in main project

## Step 1: Prepare Main Project

### Create Base docker-compose.yml

Your main project needs a `docker-compose.yml` with standard ports:

```yaml
# docker-compose.yml (in main project root)
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"  # Standard port - runs normally in main
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    ports:
      - "5432:5432"  # Standard port - runs normally in main
    environment:
      - POSTGRES_DB=myapp_dev
      - POSTGRES_USER=dev
      - POSTGRES_PASSWORD=dev
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"  # Standard port - runs normally in main

volumes:
  db_data:
```

**Why include ports in main?**
- Main project runs normally with `docker-compose up`
- You get a clean "mainline" version at standard ports
- Worktrees override these ports with unique ones
- No conflicts between main and worktrees

### Add to .gitignore

```bash
# .gitignore
docker-compose.override.yml
.env.docker
.docker-ports.json
.docker-ports.lock
```

These files are auto-generated per feature and shouldn't be committed.

## Step 2: Using Docker in Features

### Basic Workflow

```bash
# In main - create feature
/feature-start "add user authentication"
/feature-plan
/feature-prep

# New VS Code window opens
# In worktree - start Docker
/feature-docker start

# Output shows:
# ✓ Docker containers started for feature: user-authentication
#
# Access your app at:
#   App:   http://localhost:3031
#   DB:    localhost:5463
#   Redis: localhost:6410
#
# Database is empty. To seed from main:
#   /feature-docker seed

# Seed database with realistic data
/feature-docker seed

# Now build your feature
/feature-build

# Test at http://localhost:3031
# Each task can be tested immediately

# When done
/feature-docker down
/feature-end
```

## Port Assignment

### How Ports Are Calculated

1. **Hash feature name** → generates consistent number
2. **Calculate offset** → hash % 50 (range: 0-49)
3. **Add to base ports**:
   - App: 3000 + offset
   - DB: 5432 + offset
   - Redis: 6379 + offset

### Example Assignments

| Environment | Offset | App | DB | Redis |
|-------------|--------|-----|-----|-------|
| **main** | 0 | 3000 | 5432 | 6379 |
| dark-mode | 7 | 3007 | 5439 | 6386 |
| user-auth | 31 | 3031 | 5463 | 6410 |
| email-notif | 23 | 3023 | 5455 | 6402 |

**Main project:**
- Uses standard ports from `docker-compose.yml`
- No offset, no override file
- Run with: `docker-compose up`

**Worktrees:**
- Override main's ports with calculated unique ports
- Each gets offset based on feature name hash
- Run with: `/feature-docker start` (uses override file)

### Port Collision Handling

If calculated port is in use:
- Automatically tries next port (+1, +2, +3...)
- Max 10 attempts
- Stores assignment in `.docker-ports.json` for consistency

## Generated Files

When you run `/feature-docker start` for the first time:

### docker-compose.override.yml

```yaml
# Auto-generated in worktree
# Overrides ports from main's docker-compose.yml
version: '3.8'

services:
  app:
    ports:
      - "3031:3000"  # Replaces main's 3000:3000
    environment:
      - FEATURE_NAME=user-authentication
      - APP_PORT=3031

  db:
    ports:
      - "5463:5432"  # Replaces main's 5432:5432

  redis:
    ports:
      - "6410:6379"  # Replaces main's 6379:6379
```

**How it works:**
- Docker Compose merges base + override files
- Override takes precedence for conflicting keys
- Ports are replaced, not merged
- Other config (volumes, environment) is inherited from main

### .env.docker

```bash
# Auto-generated in worktree
FEATURE_NAME=user-authentication
APP_PORT=3031
DB_PORT=5463
REDIS_PORT=6410
```

## Commands Reference

### /feature-docker start

Start Docker containers for current feature:
```bash
/feature-docker start
```

Creates override files, starts containers, shows URLs.

### /feature-docker stop

Stop containers but preserve data:
```bash
/feature-docker stop
```

Containers stopped, volumes remain. Quick restart with `start`.

### /feature-docker restart

Restart all containers:
```bash
/feature-docker restart
```

Useful after code changes that need restart.

### /feature-docker seed

Copy database from main to feature:
```bash
/feature-docker seed
```

Seeds feature database with data from main's development database. Gives you realistic test data instead of starting empty.

**Process:**
1. Connects to main database (port 5432)
2. Dumps all data
3. Restores to feature database (unique port)
4. Reports success

**Use when:**
- Testing features that need existing users
- Working with existing data structures
- Avoiding manual data entry
- Integration testing

**Note:** Main's Docker must be running (or command will start it temporarily)

### /feature-docker logs

View container logs:
```bash
/feature-docker logs
```

Shows last 100 lines, follows new logs (Ctrl+C to exit).

### /feature-docker ps

Show container status:
```bash
/feature-docker ps
```

Lists all containers for this feature with status.

### /feature-docker ports

Show assigned ports:
```bash
/feature-docker ports
```

Displays URLs for accessing services.

### /feature-docker down

Stop and remove containers + volumes:
```bash
/feature-docker down
```

⚠️ **Warning:** This deletes all data (database, uploads, etc.)

Use when:
- Finishing feature development
- Want fresh environment
- Need to free resources

## Working with Databases

### Running Migrations

After starting Docker:

```bash
# Node.js / Prisma
docker-compose exec app npx prisma migrate dev

# Django
docker-compose exec app python manage.py migrate

# Rails
docker-compose exec app rails db:migrate

# Direct SQL
docker-compose exec db psql -U dev -d myapp_dev
```

### Seeding Data

```bash
docker-compose exec app npm run seed
# or
docker-compose exec app python manage.py loaddata fixtures.json
```

### Resetting Database

```bash
/feature-docker down
/feature-docker start
# Fresh database!

# Then re-run migrations and seeds
docker-compose exec app npm run migrate
docker-compose exec app npm run seed
```

### Seeding from Main Database

Most features need realistic data to test properly. Copy data from main:

```bash
# Start feature Docker
/feature-docker start

# Seed from main's database
/feature-docker seed

# ✓ Database seeded from main
# Tables copied: 25
# Approximate rows: 15,432
```

**What gets copied:**
- All table structures (if not from migrations)
- All data from main's development database
- Sequences and indexes
- Foreign key relationships

**When to seed:**
- Testing features that need existing users
- Testing modifications to existing data
- Integration testing with realistic data
- Avoiding manual data entry

**Fresh start:**
```bash
# Reset feature database
/feature-docker down
/feature-docker start
/feature-docker seed
# Clean slate with main's data!
```

**Manual seeding (PostgreSQL):**
```bash
# Dump from main (port 5432)
pg_dump -h localhost -p 5432 -U dev myapp_dev > backup.sql

# Restore to feature (port 5439 - check your .env.docker)
psql -h localhost -p 5439 -U dev myapp_dev < backup.sql
```

**Manual seeding (MySQL):**
```bash
# Dump from main
mysqldump -h localhost -P 3306 -u dev myapp_dev > backup.sql

# Restore to feature (port 3307 - check your .env.docker)
mysql -h localhost -P 3307 -u dev myapp_dev < backup.sql
```

## Multiple Features Running

### Parallel Development

You can run Docker for multiple features simultaneously:

```bash
# Terminal 1 - Feature A worktree
cd ../myapp.worktrees/feature-a
/feature-docker start
# → Running on localhost:3007

# Terminal 2 - Feature B worktree
cd ../myapp.worktrees/feature-b
/feature-docker start
# → Running on localhost:3023

# Terminal 3 - Feature C worktree
cd ../myapp.worktrees/feature-c
/feature-docker start
# → Running on localhost:3015
```

All three features run independently with isolated data!

### Resource Monitoring

Check resource usage:
```bash
docker stats
```

Shows CPU, memory, network for all containers.

### Cleanup

Stop unused features to free resources:
```bash
# In each unused worktree
/feature-docker down
```

## Environment Variables

### Precedence

Environment variables are merged from:
1. **Main .env** (symlinked) - shared config
2. **.env.docker** (generated) - feature-specific ports
3. **docker-compose.override.yml** - container config

Later sources override earlier ones.

### Custom Variables

Add feature-specific variables to `.env.docker`:

```bash
# .env.docker
FEATURE_NAME=user-authentication
APP_PORT=3031
DB_PORT=5463
REDIS_PORT=6410

# Your custom variables
ENABLE_NEW_AUTH=true
DEBUG_LEVEL=verbose
```

## Advanced Configuration

### Adding Custom Services

Edit `docker-compose.override.yml` in worktree:

```yaml
# Add Elasticsearch for search feature
services:
  elasticsearch:
    image: elasticsearch:8.10
    ports:
      - "9207:9200"
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
```

Update `.env.docker`:
```bash
ELASTIC_PORT=9207
```

### Using Different Base Images

Override base image in worktree:

```yaml
services:
  app:
    image: node:20-alpine  # Instead of building from Dockerfile
    volumes:
      - .:/app
    command: npm run dev
```

### Volume Strategies

**Isolated volumes (default):**
```yaml
volumes:
  db_data:  # Unique per feature
```

**Shared volumes:**
```yaml
volumes:
  db_data:
    name: myapp_shared_db  # Shared across features
```

## Testing Strategies

### Unit Tests with Test Database

```bash
/feature-docker start

# Run tests against feature database
npm test
# or
pytest

# Tests use FEATURE_NAME environment variable
# to isolate test data
```

### Integration Tests

```bash
/feature-docker start

# Hit feature endpoints
curl http://localhost:3031/api/health

# Run E2E tests
npm run test:e2e -- --base-url=http://localhost:3031
```

### Load Testing

```bash
/feature-docker start

# Use feature-specific URL
ab -n 1000 -c 10 http://localhost:3031/api/endpoint
```

## Troubleshooting

### "Port already in use"

System automatically tries alternative ports. If all fail:
```bash
# Check what's using the port
lsof -i :3031

# Kill process or wait for auto-assignment
```

### "Cannot connect to Docker daemon"

```bash
# Start Docker Desktop
open -a Docker  # macOS
# or start Docker Desktop manually

# Verify Docker is running
docker ps
```

### Containers fail to start

```bash
# Check logs
/feature-docker logs

# Common issues:
# - Build errors: Fix Dockerfile
# - Port conflicts: Handled automatically
# - Missing dependencies: docker-compose pull
```

### Database connection errors

```bash
# Database might still be initializing
# Wait 10 seconds and try again

# Check database logs
docker-compose logs db

# Verify database is ready
docker-compose exec db pg_isready
```

### Database seeding fails

**Main database not running:**
```bash
# Start main's Docker first
cd ~/projects/myapp  # main directory
docker-compose up -d

# Verify main DB is accessible
docker ps | grep postgres
# Should show container on port 5432

# Then seed from worktree
cd ../myapp.worktrees/feature-name
/feature-docker seed
```

**Permission denied:**
```bash
# Ensure both databases use same credentials
# Check main's docker-compose.yml matches feature's

# Default credentials should be:
# POSTGRES_USER=dev
# POSTGRES_PASSWORD=dev
```

**Table already exists:**
```bash
# Feature database isn't empty
# Reset and try again:
/feature-docker down
/feature-docker start
/feature-docker seed
```

**Wrong database type:**
```bash
# Verify main and feature use same DB engine
# PostgreSQL seed won't work with MySQL

# Check main's docker-compose.yml
grep "image:" docker-compose.yml
```

### "No docker-compose.yml found"

Ensure main project has `docker-compose.yml`:
```bash
ls docker-compose.yml  # In main project
```

### Symlinked .env not working

```bash
# Verify symlink exists
ls -la .env

# Recreate if broken
ln -s ../../<project>/.env .env
```

## Best Practices

### Resource Management

✅ **Do:**
- Stop Docker when not actively testing
- Use `down` to clean up completed features
- Keep 2-3 features running max
- Monitor with `docker stats`

❌ **Don't:**
- Leave all features running overnight
- Let volumes accumulate without cleanup
- Run Docker for features you're not testing

### Data Management

✅ **Do:**
- Use `down` for fresh testing environment
- Commit database migrations to git
- Seed test data from scripts
- Use unique feature prefixes in test data

❌ **Don't:**
- Rely on persistent data across features
- Share volumes between features (usually)
- Commit docker-compose.override.yml

### Development Workflow

✅ **Do:**
- Start Docker before intensive testing
- Test each task incrementally
- Restart after config changes
- Check logs when things break

❌ **Don't:**
- Keep Docker running when not needed
- Ignore resource warnings
- Mix feature-specific and shared volumes without planning

## Example: Complete Feature Lifecycle

```bash
# ══════════════════════════════════════
# 1. PLANNING (in main)
# ══════════════════════════════════════

/feature-start "add real-time notifications"
/feature-plan
/feature-prep

# ══════════════════════════════════════
# 2. SETUP DOCKER (in worktree)
# ══════════════════════════════════════

/feature-docker start

# ✓ Docker containers started for feature: real-time-notifications
# Access your app at: http://localhost:3042
# Database is empty. To seed from main:
#   /feature-docker seed

/feature-docker seed

# ✓ Database seeded from main
# Tables copied: 25
# Approximate rows: 15,432

# ══════════════════════════════════════
# 3. DEVELOP & TEST (in worktree)
# ══════════════════════════════════════

/feature-build

# After implementing WebSocket support:
# Test at http://localhost:3042
curl http://localhost:3042/api/notifications/subscribe

# Run migrations for notification schema
docker-compose exec app npx prisma migrate dev

# Test with existing users from seeded database
# No need to create test accounts manually!

# ══════════════════════════════════════
# 4. ITERATIVE TESTING
# ══════════════════════════════════════

# Make changes, test, repeat
# Restart when needed:
/feature-docker restart

# View logs to debug:
/feature-docker logs

# ══════════════════════════════════════
# 5. CLEANUP & MERGE (in worktree)
# ══════════════════════════════════════

/feature-docker down
# ✓ Containers stopped and removed

/feature-end
# ✓ Feature merged to main

# Docker resources freed, worktree deleted!
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Main Project                                                 │
├─────────────────────────────────────────────────────────────┤
│ docker-compose.yml (base config with standard ports)        │
│ .env (shared config) ─────────────┐                         │
└───────────────────────────────────┼─────────────────────────┘
                                    │ symlink
┌───────────────────────────────────┼─────────────────────────┐
│ Worktree: feature-a               ▼                         │
├─────────────────────────────────────────────────────────────┤
│ docker-compose.override.yml (ports: 3007, 5439, 6386)      │
│ .env.docker (FEATURE_NAME=feature-a, APP_PORT=3007)        │
│ .env → ../../main/.env                                      │
├─────────────────────────────────────────────────────────────┤
│ Containers: app:3007, db:5439, redis:6386                  │
│ Volumes: feature-a_db_data (isolated)                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Worktree: feature-b               ▲                         │
├───────────────────────────────────┼─────────────────────────┤
│ docker-compose.override.yml (ports: 3023, 5455, 6402)      │
│ .env.docker (FEATURE_NAME=feature-b, APP_PORT=3023)        │
│ .env → ../../main/.env ────────────┘                        │
├─────────────────────────────────────────────────────────────┤
│ Containers: app:3023, db:5455, redis:6402                  │
│ Volumes: feature-b_db_data (isolated)                      │
└─────────────────────────────────────────────────────────────┘

Main runs on standard ports (3000, 5432, 6379)
All worktrees share:
- Base docker-compose.yml
- Main .env (via symlink)
- Docker images (built once)

Each worktree has unique:
- Ports (overrides main's ports)
- Containers (isolated processes)
- Volumes (isolated data)
- Override config
```

## Summary

**Isolated Docker environments give you:**
- 🔸 Test each feature independently
- 🔸 Multiple features running in parallel
- 🔸 Clean slate for testing (easy reset)
- 🔸 No conflicts or interference
- 🔸 Consistent with production setup

**Commands you'll use:**
- `/feature-docker start` - Begin testing
- `/feature-docker logs` - Debug issues
- `/feature-docker restart` - Apply changes
- `/feature-docker down` - Cleanup

Start with simple features, graduate to complex multi-feature development with confidence!
