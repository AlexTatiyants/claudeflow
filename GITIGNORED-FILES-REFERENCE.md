# Gitignored Files in Worktrees - Quick Reference

## The Problem

Git worktrees only include **tracked files**. Gitignored directories like `.claude/`, `.env`, and `.vscode/` are not automatically copied to worktrees.

**This means:**
- ❌ Environment variables missing (no `.env` files)
- ❌ VS Code settings not shared (no `.vscode/` settings)

**Note:** Commands in `.claude/commands/` are tracked in git and available in all worktrees automatically.

## The Solution: Symlinks

Create symbolic links from main to worktree so all worktrees share the same gitignored files.

### Automated (in /feature-prep)

The `/feature-prep` command should automatically create these symlinks:

```bash
# In worktree directory
ln -s ../../<project>/.env .env
ln -s ../../<project>/.env.local .env.local  # if exists
ln -s ../../<project>/.vscode .vscode        # optional
```

### Manual Setup (if needed)

If `/feature-prep` didn't create symlinks or you need to add more:

```bash
# Navigate to worktree
cd ../<project-name>.worktrees/<feature-name>/

# Recommended: Environment files
ln -s ../../<project-name>/.env .env
ln -s ../../<project-name>/.env.local .env.local

# Optional: Editor settings
ln -s ../../<project-name>/.vscode .vscode

# Verify symlinks
ls -la
# Should show: .env -> ../../project/.env
```

## What to Symlink

| Directory/File | Symlink? | Reason |
|---------------|----------|---------|
| `.env*` | ✅ Yes | Share environment config |
| `.vscode/` | ⚠️ Optional | Share editor settings (or use separate) |
| `.claude/` | ❌ No | Commands in git, settings are feature-specific |
| `node_modules/` | ❌ No | Run `npm install` per worktree |
| `venv/`, `__pycache__/` | ❌ No | Regenerate per worktree |
| `.next/`, `dist/`, `build/` | ❌ No | Build outputs, regenerate |
| `.git/` | ➖ N/A | Handled automatically by git worktree |

## Benefits of Symlinking

✓ **Consistent environment** - All worktrees use same `.env` variables
✓ **Less disk space** - Single copy of directories like `.vscode/`
✓ **Simpler setup** - Don't need to copy files to each worktree
✓ **Commands in git** - Update commands once, committed to repo, available everywhere

## After Creating Symlinks

1. **Restart Claude Code extension** in VS Code
   - Command Palette (Cmd/Ctrl+Shift+P) → "Developer: Reload Window"
   - Or close and reopen VS Code

2. **Verify environment**
   ```bash
   # Check .env is available
   ls -la .env
   # Should show symlink
   ```

## Troubleshooting

### Symlink doesn't work

**Check if symlink was created:**
```bash
ls -la | grep .env
# Should show: .env -> ../../project/.env
```

**If broken symlink:**
```bash
# Remove broken symlink
rm .env

# Recreate with correct path
ln -s ../../<correct-project-name>/.env .env
```

### Environment variables not available

1. Check symlink points to correct location
2. Ensure `.env` exists in main project
3. Verify worktree path is correct (../../project-name/)

### Can't create symlink on Windows

Use Git Bash or WSL for symlink support, or:

```cmd
# Windows CMD (requires admin)
mklink /D .claude ..\..\project\.claude

# Windows PowerShell (requires admin)
New-Item -ItemType SymbolicLink -Path ".claude" -Target "..\..\project\.claude"
```

## Best Practices

1. **Symlink during /feature-prep** - Automate it so you don't forget
2. **Document project-specific needs** - Some projects need additional symlinks
3. **Don't symlink build outputs** - Let each worktree build independently
4. **Don't symlink .claude** - Commands are in git, settings are feature-specific
5. **Test in one worktree first** - Verify setup works before creating many worktrees

## Example: Complete Setup

```bash
# Start in main
cd ~/projects/my-app

# Create feature
/feature-start "add dark mode"
/feature-plan
/feature-prep

# New VS Code window opens at: ~/projects/my-app.worktrees/dark-mode/
# Symlinks should already exist, but verify:
ls -la .env .vscode

# If missing, create manually:
ln -s ../../my-app/.env .env
ln -s ../../my-app/.vscode .vscode

# Commands are available from git:
/feature-build
# ✓ Should work!
```

## Architecture Note

```
my-app/                          (main)
├── .claude/
│   ├── commands/                (tracked in git)
│   │   ├── feature-start.md
│   │   ├── feature-build.md
│   │   └── ...
│   └── settings.local.json      (gitignored, feature-specific)
├── .env                         (gitignored)
└── src/

my-app.worktrees/dark-mode/      (worktree)
├── .claude/
│   ├── commands/                (from git)
│   └── settings.local.json      (unique to this feature)
├── .env -> ../../my-app/.env    (symlink)
└── src/                         (from git)

my-app.worktrees/email-notif/    (worktree)
├── .claude/
│   ├── commands/                (from git)
│   └── settings.local.json      (unique to this feature)
├── .env -> ../../my-app/.env    (symlink)
└── src/                         (from git)
```

Commands are shared via git, .env is shared via symlink, settings are feature-specific!
