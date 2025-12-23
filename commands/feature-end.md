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
   - Stage all changes: `git add .`
   - Commit with descriptive message summarizing the feature
   - Include brief bullet list of main changes
   - Reference completed tasks: TSK1, TSK2, TSK3, ...

### Phase 2: Merge to Main

1. **Switch to main**
   - Navigate to main branch directory
   - Ensure main is clean

2. **Attempt merge**
   - Run: `git merge feature/<feature-name>`
   - Check for conflicts

### Phase 3A: Clean Merge (no conflicts)

1. **Success message**
   ```
   ✓ Feature merged successfully!
   
   Summary:
   - X files changed
   - Y insertions, Z deletions
   - Branch: feature/<feature-name> merged to main
   
   Cleaning up...
   ```

2. **Delete worktree**
   - Run: `git worktree remove ../<project>.worktrees/<feature-name>`
   - Confirm deletion

3. **Final message**
   ```
   🎉 Feature complete!
   
   The feature '<feature-name>' has been merged to main.
   Worktree has been cleaned up.
   
   You can now:
   - Start a new feature with /feature-start
   - Continue work on other features
   - Push changes: git push origin main
   ```

### Phase 3B: Merge Conflicts

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
   - Same as Phase 3A cleanup

4. **Success message**
   ```
   ✓ Conflicts resolved and merged!
   
   Feature '<feature-name>' is now in main.
   Worktree cleaned up.
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

## Important Notes

- This is a destructive operation (deletes worktree)
- Make sure all work is committed before running
- Cannot be undone once worktree is deleted
- Feature branch remains in git history
- If you need to keep working, don't run this yet
