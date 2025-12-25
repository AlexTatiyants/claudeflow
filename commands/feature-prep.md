---
description: Prepare feature for development - create worktree and task list
argument-hint: [optional-feature-name]
---

Prepare feature for development: $ARGUMENTS

## Auto-Detection Logic

1. **Check for feature name argument**
   - If provided: use that feature
   - If not provided: look in `work/features/` for uncommitted folders

2. **Handle multiple features**
   - If exactly ONE uncommitted feature: use it automatically
   - If MULTIPLE uncommitted features: list them and ask which one
   - If NO uncommitted features: show error

3. **Validate feature is ready**
   - Ensure `work/features/<feature-name>/` exists
   - Ensure `reqs.md` exists
   - Ensure `plan.md` exists
   - If anything is missing, show error with what's needed

## Workflow

1. **Generate task list**
   - Read `plan.md` from the feature folder
   - Extract all implementation steps
   - Create `tasks.md` with numbered task IDs (TSK1, TSK2, etc.)
   - Each task should be atomic and testable

2. **Create git worktree**
   - Determine project name from current directory
   - Create worktree at `../<project-name>.worktrees/<feature-name>/`
   - Auto-create parent directory if it doesn't exist
   - Create branch: `feature/<feature-name>`

3. **Move feature folder to worktree**
   - Move entire `work/features/<feature-name>/` directory
   - From: `<project>/work/features/<feature-name>/`
   - To: `<project>.worktrees/<feature-name>/work/features/<feature-name>/`
   - This removes it from main (no longer uncommitted there)

4. **Handle gitignored files**
   - Git worktrees don't include gitignored files like `.claude/`, `.env`, etc.
   - Symlink essential directories from main to worktree:
     - `.claude/` → so commands are available
     - `.env` files → so environment config is shared
     - `.vscode/` → optional, for editor settings
   - Command: `ln -s ../../<project>/.claude .claude`
   - This ensures `/feature-build` and other commands work in worktree

5. **Open VS Code**
   - Run: `code ../<project-name>.worktrees/<feature-name>/`
   - Inform user: "New VS Code window should open. Switch to it and run `/feature-build` to start implementation."
   - Optionally mention: "Run `/feature-docker start` to launch isolated Docker environment for testing."

## Task List Template (tasks.md)

```markdown
# Task List: <Feature Name>

## Summary

<2-3 sentence summary distilled from plan.md: what the feature does and key architectural decisions. This provides context for new sessions without needing to read the full plan.>

> ⚠️ **IMPORTANT:** Complete ONE task at a time. After each task, STOP and wait for user feedback before continuing. Never implement multiple tasks without pausing.

## Implementation Tasks

### <Group 1: Logical grouping name, e.g., "Data Layer">

- [ ] TSK1: [Brief task description]
  - **What:** Detailed explanation of what needs to be done
  - **Files:** List of files to create/modify
  - **Acceptance:** How to verify this task is complete
  - **Notes:** Any important considerations

- [ ] TSK2: [Brief task description]
  - **What:** Detailed explanation of what needs to be done
  - **Files:** List of files to create/modify
  - **Acceptance:** How to verify this task is complete
  - **Notes:** Any important considerations

📍 **Commit Point:** "<Suggested commit message for this group>"

### <Group 2: Next logical grouping, e.g., "API Layer">

- [ ] TSK3: [Brief task description]
  - **What:** Detailed explanation of what needs to be done
  - **Files:** List of files to create/modify
  - **Acceptance:** How to verify this task is complete
  - **Notes:** Any important considerations

- [ ] TSK4: [Brief task description]
  - **What:** Detailed explanation of what needs to be done
  - **Files:** List of files to create/modify
  - **Acceptance:** How to verify this task is complete
  - **Notes:** Any important considerations

📍 **Commit Point:** "<Suggested commit message for this group>"

### <Group 3: Continue as needed, e.g., "UI Components">

- [ ] TSK5: [Brief task description]
  - **What:** Detailed explanation of what needs to be done
  - **Files:** List of files to create/modify
  - **Acceptance:** How to verify this task is complete
  - **Notes:** Any important considerations

📍 **Commit Point:** "<Suggested commit message for this group>"

## Testing Tasks

- [ ] TSK10: Write unit tests for [component]
  - **What:** Test coverage for core functionality
  - **Files:** Test files to create
  - **Acceptance:** All tests passing

- [ ] TSK11: Integration testing
  - **What:** End-to-end testing scenarios
  - **Files:** Integration test files
  - **Acceptance:** All user flows working

📍 **Commit Point:** "Add tests for <feature name>"

## Documentation Tasks

- [ ] TSK20: Update documentation
  - **What:** Document new feature for users/developers
  - **Files:** README, API docs, etc.
  - **Acceptance:** Documentation is clear and complete

📍 **Commit Point:** "Add documentation for <feature name>"

## Completion Checklist

- [ ] All tasks completed and marked with [x]
- [ ] Code reviewed locally
- [ ] Tests passing
- [ ] No console errors or warnings
- [ ] Ready to merge
```

## Commit Point Guidelines

When creating the task list, group related tasks together and add commit points after each logical unit. Good commit points:

- **Are self-contained:** The code works after this commit (no broken intermediate states)
- **Have clear scope:** One sentence describes what the commit does
- **Are meaningful:** Each commit adds recognizable value or functionality

Examples of good groupings:
- Data models + validation logic → "Add user data model with validation"
- API endpoints + error handling → "Add user CRUD API endpoints"
- UI components + styling → "Add user management UI"
- Tests for a feature area → "Add tests for user authentication"

## Important Notes
- Each task should be granular enough to complete in one session
- Tasks are worked through one at a time in `/feature-build`
- NEVER commit without permission during `/feature-build`
- After prep completes, switch to new VS Code window and run `/feature-build`

## Gitignored Files - Critical!

Git worktrees only include tracked files. Gitignored directories like `.claude/`, `.env`, etc. won't be in the worktree by default.

**Essential symlinks to create:**
```bash
cd ../<project>.worktrees/<feature-name>/

# Commands directory (REQUIRED for /feature-build to work)
ln -s ../../<project>/.claude .claude

# Environment variables (if you have .env files)
ln -s ../../<project>/.env .env
ln -s ../../<project>/.env.local .env.local

# VS Code settings (optional - if you want shared settings)
ln -s ../../<project>/.vscode .vscode
```

**What to symlink:**
- ✓ `.claude/` - Required for commands
- ✓ `*.env*` files - For environment config
- ✓ `.vscode/` - If you want shared editor settings
- ✗ Dependencies directories - Reinstall in worktree instead (e.g., node_modules, vendor, venv)
- ✗ `.git/` - Already handled by git worktree

**Why symlinks?**
- All worktrees share the same commands
- Update commands once, available everywhere
- Consistent environment across worktrees
- Less disk space usage

After symlinking, restart Claude Code extension in VS Code to pick up commands.

## Error Messages

If feature is not ready:
```
Error: Feature '<feature-name>' is not ready for prep.

Missing:
- [ ] reqs.md (run /feature-start first)
- [x] plan.md
- [ ] feature not found

Complete the missing items before running /feature-prep.
```

## Extensions
Check for `.claude/claudeflow-extensions/feature-prep.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.
