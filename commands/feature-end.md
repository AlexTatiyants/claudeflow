---
description: Complete feature - commit, merge to main, and cleanup
argument-hint: (none - works in current worktree)
---

Complete and merge feature from current worktree

## Detection Logic

1. **Validate location**
   - Must be run in a worktree (not main)
   - Detect feature name from current directory path
   - Find feature folder in `work/features/`

2. **Pre-flight checks**
   - Ensure all tasks are complete (all boxes checked in tasks.md)
   - Warn if there are unchecked tasks
   - Check for uncommitted changes

## Workflow

### Phase 1: Review & Commit

1. **Check for running Docker containers**
   - If Docker containers are running, ask: "Stop Docker containers? (yes/no)"
   - If yes: run `/feature-docker down` to cleanup
   - If no: warn that containers will remain running

2. **Show summary**
   ```
   Feature: <feature-name>
   Branch: feature/<feature-name>
   
   Files changed:
   - work/features/<feature-name>/tasks.md (modified)
   - src/components/NewComponent.tsx (created)
   - src/lib/utils.ts (modified)
   - ... (list all changes)
   
   Tasks completed: X/Y
   ```

3. **Check task completion**
   - If not all tasks checked: "⚠️ Warning: X tasks still unchecked. Continue anyway? (yes/no)"
   - If all complete: "✓ All tasks complete"

4. **Ask for confirmation**
   - "Ready to commit and merge? This will:"
   - "  1. Commit all changes in this worktree"
   - "  2. Merge to main branch"
   - "  3. Delete this worktree"
   - "Type 'yes' to proceed"

5. **Commit changes**
   - Stage all changes:
     ```bash
     git add .
     git add work/features/<feature-name>/reqs.md
     git add work/features/<feature-name>/plan.md
     git add work/features/<feature-name>/tasks.md
     git status  # verify all files staged, including work/features/
     ```
   - Commit with descriptive message summarizing the feature
   - Include brief bullet list of main changes
   - Reference completed tasks: TSK1, TSK2, TSK3, ...

### Phase 2: Generate Feature Summary

1. **Gather commit history**
   - Get all commits since branch diverged from main:
     ```bash
     git log main..HEAD --oneline
     git log main..HEAD --format="%H %s" # for detailed parsing
     ```
   - Get diff statistics: `git diff main...HEAD --stat`
   - Get first commit timestamp: `git log main..HEAD --format="%ai" | tail -1`

2. **Analyze and synthesize**
   - Parse commit messages to understand what was done
   - Identify key changes from the diff (new files, modified files, deleted files)
   - Calculate duration from first commit to now
   - Cross-reference with tasks.md and reqs.md for context

3. **Write summary.md to feature folder**
   ```markdown
   # Feature Summary: <feature-name>

   **Completed:** <current date>
   **Duration:** <time from first commit to now>
   **Branch:** feature/<feature-name>

   ## What was built
   <2-4 bullet points synthesized from commits and tasks.md>

   ## Key decisions
   <any notable implementation choices evident from commits/code - omit if none>

   ## Changes
   - X files changed (Y new, Z modified, W deleted)
   - Key files:
     - path/to/file.ts - <brief description>
     - ...

   ## Commits
   - <hash> <message>
   - <hash> <message>
   - ...
   ```

4. **Stage summary.md**
   ```bash
   git add work/features/<feature-name>/summary.md
   ```

### Phase 3: Merge to Main

1. **Switch to main**
   - Navigate to main branch directory
   - Ensure main is clean

2. **Attempt merge**
   - Run: `git merge feature/<feature-name>`
   - Check for conflicts

### Phase 4A: Clean Merge (no conflicts)

1. **Verify feature folder exists in main**
   - Check that `work/features/<feature-name>/` now exists in main
   - If missing, this indicates it wasn't committed properly - warn user
   - The folder should contain: reqs.md, plan.md, tasks.md, summary.md

2. **Success message**
   ```
   ✓ Feature merged successfully!

   Summary:
   - X files changed
   - Y insertions, Z deletions
   - Branch: feature/<feature-name> merged to main
   - Feature docs preserved in work/features/<feature-name>/ (including summary.md)

   Cleaning up...
   ```

3. **Delete worktree**
   - Run: `git worktree remove ../<project>.worktrees/<feature-name>`
   - Confirm deletion

### Phase 5: Post-Merge Environment Update

After merging to main, the main environment often needs updating. Analyze changes and run necessary commands.

1. **Analyze what changed**
   - Check diff: `git show --name-only --format="" HEAD`
   - Look for files that require environment updates:
     - `package.json`, `package-lock.json`, `yarn.lock` → dependencies changed
     - `requirements.txt`, `Pipfile`, `Cargo.toml` → dependencies changed
     - `Dockerfile`, `docker-compose.yml` → Docker rebuild needed
     - Migration files (e.g., `prisma/migrations/*`, `db/migrate/*`, `alembic/versions/*`) → migrations needed
     - `.env.example` → environment variables may have changed

2. **Detect Docker configuration**
   - Check if `docker-compose.yml` exists in main
   - If yes, post-merge steps should run in Docker
   - If no, run locally

3. **Determine required steps**
   Based on what changed, create a checklist:
   - [ ] Install/update dependencies
   - [ ] Run database migrations
   - [ ] Rebuild Docker containers
   - [ ] Restart services

4. **Present post-merge actions**
   ```
   📋 Post-merge updates needed:

   The following changes require environment updates on main:

   Changes detected:
   - Dependencies updated (package.json)
   - New database migrations (prisma/migrations/...)
   - Docker configuration changed (docker-compose.yml)

   Recommended actions:
   1. Rebuild and restart Docker: docker-compose down && docker-compose up -d --build
   2. Run migrations: docker-compose exec app npx prisma migrate deploy
   3. (Optional) Seed database: docker-compose exec app npm run db:seed

   Run these now? (yes/no/manual)
   ```

5. **Execute post-merge steps**
   - If user says "yes": Run the commands automatically
   - If user says "no": Skip and show the commands for later
   - If user says "manual": Show the commands and wait

6. **Docker-specific execution**
   If Docker is configured, run all commands inside containers:

   **Install dependencies:**
   - `docker-compose down` (stop current containers)
   - `docker-compose up -d --build` (rebuild with new dependencies)

   **Run migrations:**
   - `docker-compose exec app npx prisma migrate deploy` (Prisma)
   - `docker-compose exec app npm run db:migrate` (generic npm script)
   - `docker-compose exec app python manage.py migrate` (Django)
   - `docker-compose exec app flask db upgrade` (Flask)
   - Adjust based on detected framework

   **Verify services:**
   - `docker-compose ps` (show running containers)
   - Display URLs for accessing the application

7. **Local execution (no Docker)**
   If no Docker configuration, run locally:
   - `npm install` or equivalent for dependencies
   - Run migration command based on framework
   - Restart development server if running

8. **Show completion status**
   ```
   ✓ Environment updated successfully!

   Services status:
   - web: running on http://localhost:3000
   - db: running on localhost:5432

   Main branch is ready for development.
   ```

4. **Final message**
   ```
   🎉 Feature complete!

   The feature '<feature-name>' has been merged to main.
   Worktree has been cleaned up.
   Environment has been updated.

   You can now:
   - Start a new feature with /feature-start
   - Continue work on other features
   - Push changes: git push origin main
   ```

### Phase 4B: Merge Conflicts

1. **Conflict detected message**
   ```
   ⚠️ Merge conflicts detected!
   
   Conflicted files:
   - src/components/Header.tsx
   - src/lib/config.ts
   
   To resolve:
   1. Stay in this VS Code window
   2. Open each conflicted file
   3. Resolve conflicts (look for <<<<<<< markers)
   4. Save all files
   5. Stage resolved files: git add <file>
   6. Run /feature-merge-continue
   
   DO NOT run git commit manually.
   ```

2. **Stop and wait**
   - Do not proceed further
   - User must resolve conflicts manually

## Helper Command: /feature-merge-continue

Create a companion command for conflict resolution:

```markdown
---
description: Continue merge after resolving conflicts
argument-hint: (none)
---

Continue feature merge after conflict resolution

## Workflow

1. **Verify conflicts resolved**
   - Check git status
   - Ensure no files with conflict markers remain
   - All conflicts should be staged

2. **Complete merge**
   - Run: `git merge --continue`
   - Use existing commit message

3. **Delete worktree**
   - Same as Phase 4A cleanup

4. **Post-merge environment update**
   - Run Phase 5 (Post-Merge Environment Update) from feature-end
   - Analyze changes, detect Docker, run necessary commands

5. **Success message**
   ```
   ✓ Conflicts resolved and merged!

   Feature '<feature-name>' is now in main.
   Worktree cleaned up.
   Environment updated.
   ```
```

## Safety Checks

Before merging:
- Warn if there are unstaged changes
- Warn if main branch has new commits (rebase needed?)
- Check if feature branch is up to date

## Error Messages

If not in worktree:
```
Error: This command must be run in a feature worktree.

Current location: [detected path]
Expected: A worktree in ../<project>.worktrees/
```

If git operations fail:
```
Error: Git operation failed

Command: [git command that failed]
Error: [git error message]

Please resolve manually or ask for help.
```

## Extensions
Check for `.claude/claudeflow-extensions/feature-end.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.

## Using Summary for PRs

If creating a PR instead of direct merge, the summary.md can be used to generate the PR description:
- The "What was built" section becomes the PR summary
- The "Changes" section provides context for reviewers
- The "Commits" section is already in the PR but provides quick reference

## Important Notes

- This is a destructive operation (deletes worktree)
- Make sure all work is committed before running
- Cannot be undone once worktree is deleted
- Feature branch remains in git history
- Post-merge environment updates (migrations, Docker rebuild) will run automatically on main
- If Docker is configured, all post-merge commands run inside containers
- If you need to keep working, don't run this yet
