# Database Seeding Quick Reference

## Why Seed from Main?

Fresh feature databases are empty. Most features need realistic data to test properly:
- Existing user accounts to test with
- Reference data (countries, categories, etc.)
- Sample content (posts, products, etc.)
- Configuration settings
- Relationships between entities

Without seeding, you'd need to manually recreate all this data in each feature - very time consuming!

## Quick Start

```bash
# In feature worktree
/feature-docker start
/feature-docker seed

# ✓ Database seeded from main
# Tables copied: 25
# Approximate rows: 15,432
```

That's it! Your feature database now has all the data from main.

## When to Seed

**Seed immediately after start for:**
- Features that modify existing data
- Features that need authentication (existing users)
- Integration testing
- Testing queries on realistic data volumes
- Features that depend on reference data

**Don't seed for:**
- Features adding entirely new data structures
- Performance testing (generate test data instead)
- When you specifically need empty tables
- Schema migration testing from scratch

## Common Workflows

### Standard Feature Development

```bash
/feature-docker start
/feature-docker seed
docker-compose exec app npm run migrate  # Run new migrations
/feature-build
# Test with realistic data!
```

### Testing Migrations

```bash
# Option 1: Test on seeded data (realistic)
/feature-docker start
/feature-docker seed
docker-compose exec app npm run migrate
# See how migration affects existing data

# Option 2: Test on empty database (clean slate)
/feature-docker start
docker-compose exec app npm run migrate
# Fresh schema, no data
```

### Iterative Testing

```bash
# Make changes to data during testing
# Want to reset to original state?

/feature-docker down
/feature-docker start
/feature-docker seed
# Back to original data from main
```

## How It Works

### PostgreSQL (most common)

```bash
# What /feature-docker seed does:
pg_dump -h localhost -p 5432 -U dev myapp_dev | \
  psql -h localhost -p 5439 -U dev myapp_dev

# Breakdown:
# - Connects to main DB on port 5432
# - Dumps all data (structure + content)
# - Pipes to feature DB on port 5439 (from .env.docker)
# - Restores everything
```

### MySQL

```bash
# For MySQL projects:
mysqldump -h localhost -P 3306 -u dev myapp_dev | \
  mysql -h localhost -P 3307 -u dev myapp_dev
```

### MongoDB

```bash
# For MongoDB projects:
mongodump --host localhost:27017 --db myapp_dev --out /tmp/dump
mongorestore --host localhost:27018 --db myapp_dev /tmp/dump/myapp_dev
```

## Manual Seeding

If automated seeding doesn't work, do it manually:

### Step 1: Find your ports

```bash
# In feature worktree
cat .env.docker | grep DB_PORT
# DB_PORT=5439
```

### Step 2: Dump from main

```bash
# Go to main directory
cd ~/projects/myapp

# Ensure main Docker is running
docker-compose up -d

# Dump database
docker-compose exec db pg_dump -U dev myapp_dev > /tmp/main_backup.sql

# Or without Docker:
pg_dump -h localhost -p 5432 -U dev myapp_dev > /tmp/main_backup.sql
```

### Step 3: Restore to feature

```bash
# Go to feature worktree
cd ../myapp.worktrees/feature-name

# Ensure feature Docker is running
docker-compose up -d

# Restore database
docker-compose exec -T db psql -U dev myapp_dev < /tmp/main_backup.sql

# Or without Docker (use your port from .env.docker):
psql -h localhost -p 5439 -U dev myapp_dev < /tmp/main_backup.sql
```

### Step 4: Verify

```bash
# Check table counts match
docker-compose exec db psql -U dev myapp_dev -c "\dt"

# Check row counts
docker-compose exec db psql -U dev myapp_dev -c "SELECT COUNT(*) FROM users;"
```

## Troubleshooting

### Main database not running

```bash
Error: could not connect to server: Connection refused
	Is the server running on host "localhost" and accepting
	TCP/IP connections on port 5432?
```

**Solution:**
```bash
# Start main's Docker
cd ~/projects/myapp
docker-compose up -d

# Verify it's running
docker ps | grep postgres

# Try seeding again
cd ../myapp.worktrees/feature-name
/feature-docker seed
```

### Permission denied

```bash
Error: permission denied for database myapp_dev
```

**Solution:**
```bash
# Verify credentials match between main and feature
# Check main's docker-compose.yml:
grep POSTGRES_USER docker-compose.yml
grep POSTGRES_PASSWORD docker-compose.yml

# Should be same in both (usually dev/dev)
```

### Table already exists

```bash
Error: relation "users" already exists
```

**Solution:**
```bash
# Feature database isn't empty
# Option 1: Fresh start
/feature-docker down
/feature-docker start
/feature-docker seed

# Option 2: Add --clean flag (if implementing manually)
pg_dump --clean --if-exists -h localhost -p 5432 -U dev myapp_dev | \
  psql -h localhost -p 5439 -U dev myapp_dev
```

### Out of disk space

```bash
Error: could not write to file: No space left on device
```

**Solution:**
```bash
# Clean up unused Docker volumes
docker volume prune

# Clean up unused features
cd ../myapp.worktrees
ls
# For each completed feature:
cd feature-name
/feature-docker down
cd ..
git worktree remove feature-name
```

### Slow seeding

Large databases may take time:

```bash
# Show progress (PostgreSQL)
docker-compose logs -f db

# For very large databases:
# 1. Dump to file first
pg_dump -h localhost -p 5432 -U dev myapp_dev > /tmp/backup.sql

# 2. Check file size
ls -lh /tmp/backup.sql

# 3. Restore with progress (if pv installed)
pv /tmp/backup.sql | psql -h localhost -p 5439 -U dev myapp_dev

# 4. Or restore normally (may take minutes for large DBs)
psql -h localhost -p 5439 -U dev myapp_dev < /tmp/backup.sql
```

## Advanced Scenarios

### Selective Seeding

Only seed specific tables:

```bash
# PostgreSQL - only seed users and products tables
pg_dump -h localhost -p 5432 -U dev myapp_dev \
  -t users -t products \
  | psql -h localhost -p 5439 -U dev myapp_dev
```

### Seed with Anonymized Data

For testing in production-like environments:

```bash
# Dump and anonymize in one step
pg_dump -h localhost -p 5432 -U dev myapp_dev | \
  sed "s/real@email.com/test@example.com/g" | \
  sed "s/555-1234/555-0000/g" | \
  psql -h localhost -p 5439 -U dev myapp_dev
```

### Seed from Production Backup

If you have production backups:

```bash
# Restore production backup to feature DB
# ⚠️ Warning: May contain sensitive data
gunzip -c prod_backup.sql.gz | \
  psql -h localhost -p 5439 -U dev myapp_dev

# Always anonymize production data!
```

### Incremental Updates

If main's data changed since last seed:

```bash
# Just seed again - it will replace everything
/feature-docker seed

# Or for PostgreSQL with --clean flag:
pg_dump --clean --if-exists -h localhost -p 5432 -U dev myapp_dev | \
  psql -h localhost -p 5439 -U dev myapp_dev
```

## Best Practices

✅ **Do:**
- Seed immediately after starting Docker for most features
- Reset and re-seed when data gets messy during testing
- Keep main's database in a good state (it's your seed source!)
- Document any special seeding needs in feature requirements

❌ **Don't:**
- Seed production data without anonymization
- Rely on seeded data for migration testing (test both empty and seeded)
- Forget to seed when testing user-facing features
- Leave main's Docker running continuously (wastes resources)

## Multiple Features

Each feature can seed independently:

```bash
# Feature A
cd ../myapp.worktrees/feature-a
/feature-docker seed
# Gets main's data

# Feature B
cd ../myapp.worktrees/feature-b
/feature-docker seed
# Also gets main's data (independent copy)

# Features can modify their data without affecting each other
```

## Summary

**Quick commands:**
```bash
/feature-docker seed              # Auto-seed from main
/feature-docker down && start     # Reset
/feature-docker seed              # Re-seed after reset
```

**Remember:**
- Seeding gives you realistic test data
- Each feature gets its own copy (isolated)
- Main database must be running
- Takes seconds for small DBs, minutes for large ones
- Can be done repeatedly without issues

**When in doubt:**
Seed! It's quick, safe, and makes testing much easier.
