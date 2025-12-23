# Gitignored Files in Worktrees - Quick Reference

## The Problem

Git worktrees only include **tracked files**. Gitignored directories like `.claude/`, `.env`, and `.vscode/` are not automatically copied to worktrees.

**This means:**
- ❌ `/feature-build` won't work (no `.claude/` commands)
- ❌ Environment variables missing (no `.env` files)
- ❌ VS Code settings not shared (no `.vscode/` settings)

## The Solution: Symlinks

Create symbolic links from main to worktree so all worktrees share the same gitignored files.

### Automated (in /feature-prep)

The `/feature-prep` command should automatically create these symlinks:

```bash
# In worktree directory
ln -s ../../<project>/.claude .claude
ln -s ../../<project>/.env .env
ln -s ../../<project>/.env.local .env.local  # if exists
```

### Manual Setup (if needed)

If `/feature-prep` didn't create symlinks or you need to add more:

```bash
# Navigate to worktree
cd ../<project-name>.worktrees/<feature-name>/

# Required: Commands directory
ln -s ../../<project-name>/.claude .claude

# Recommended: Environment files
ln -s ../../<project-name>/.env .env
ln -s ../../<project-name>/.env.local .env.local

# Optional: Editor settings
ln -s ../../<project-name>/.vscode .vscode

# Verify symlinks
ls -la
# Should show: .claude -> ../../project/.claude
```

## What to Symlink

| Directory/File | Symlink? | Reason |
|---------------|----------|---------|
| `.claude/` | ✅ Yes | Required for commands to work |
| `.env*` | ✅ Yes | Share environment config |
| `.vscode/` | ⚠️ Optional | Share editor settings (or use separate) |
| `node_modules/` | ❌ No | Run `npm install` per worktree |
| `venv/`, `__pycache__/` | ❌ No | Regenerate per worktree |
| `.next/`, `dist/`, `build/` | ❌ No | Build outputs, regenerate |
| `.git/` | ➖ N/A | Handled automatically by git worktree |

## Benefits of Symlinking

✓ **Update once, available everywhere** - Change commands in main, all worktrees get updates
✓ **Consistent environment** - All worktrees use same `.env` variables  
✓ **Less disk space** - Single copy of large directories like `.vscode/`
✓ **Simpler setup** - Don't need to copy files to each worktree

## After Creating Symlinks

1. **Restart Claude Code extension** in VS Code
   - Command Palette (Cmd/Ctrl+Shift+P) → "Developer: Reload Window"
   - Or close and reopen VS Code

2. **Verify commands work**
   ```bash
   # In worktree VS Code window
   /feature-build
   # Should work now!
   ```

## Troubleshooting

### Symlink doesn't work

**Check if symlink was created:**
```bash
ls -la | grep .claude
# Should show: .claude -> ../../project/.claude
```

**If broken symlink:**
```bash
# Remove broken symlink
rm .claude

# Recreate with correct path
ln -s ../../<correct-project-name>/.claude .claude
```

### Commands still not available

1. Check symlink points to correct location
2. Restart VS Code / reload window
3. Ensure `.claude/` exists in main project

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
4. **Share commands, separate builds** - Commands unified, builds isolated
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
ls -la .claude .env .vscode

# If missing, create manually:
ln -s ../../my-app/.claude .claude
ln -s ../../my-app/.env .env

# Restart VS Code, then:
/feature-build
# ✓ Should work!
```

## Architecture Note

```
my-app/                          (main)
├── .claude/                     (real directory)
│   ├── feature-start.md
│   ├── feature-build.md
│   └── ...
├── .env                         (real file)
└── src/

my-app.worktrees/dark-mode/      (worktree)
├── .claude -> ../../my-app/.claude   (symlink)
├── .env -> ../../my-app/.env         (symlink)
└── src/                              (real directory)

my-app.worktrees/email-notif/    (worktree)
├── .claude -> ../../my-app/.claude   (symlink)
├── .env -> ../../my-app/.env         (symlink)
└── src/                              (real directory)
```

All worktrees point to the same `.claude/` and `.env` in main!
