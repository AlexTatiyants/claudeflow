# Claudeflow
Claudeflow is a workflow system optimized for parallel, stepwise development using Git worktrees, Claude Code, VS Code, and Docker. 

## Why Claudeflow
Claude Code (and its agentic brethren) is a major force multiplier. It can do awesome things but it can also make life difficult:

- Without guardrails, it can generate *lots* of code, making reviews difficult
- Using it to build multiple features concurrently is tricky

Claudeflow attempts to address these issues:
- It's designed to make progress one step at a time, making it easier for a developer to review its work
- It embraces Git worktrees, VS Code, and Docker to make it easy to build stuff in parallel.

## What is Claudeflow
Claudeflow is just commands for Claude Code, nothing more. You can install it globally or into your project using `setup.sh` and then start using the commands it provides (ex. `/feature-start`). 

Customization is also straightforward (and encouraged). You can extend any command with custom instructions for your project.

## Incremental Progress
Claudeflow embraces a feature-based plan/execute workflow you can see in tools like [SpecKit](https://github.com/github/spec-kit). Start with an idea for a feature, design it, spec it, task it, and build it. When building, claudeflow will pause for your review after each task is completed, making it easier to understand and review its work. Moreover, Claudeflow makes it possible to avoid compacting because it automatically creates relevant context for the build phase.

A side benefit of using Claudeflow is a complete record of each feature (the requirements, the plan, and a task list).

## Concurrent Development
Ability to easily develop multiple features simultaneously is really the reason Claudeflow exists. When you're ready to build, Claudeflow uses Git Worktrees and Docker to isolate the feature and opens it in a separate VS Code window. It even pulls in commonly used (but usually gitignored) files/folders like .env, .claude, and .vscode into your feature folder using symlinks. That way, all your project and app settings are ready to go. 

Claudeflow can also help seed dev data from the main dev db if you need it for the feature you're working on. Finally, once you're done, it does all the cleanup and pulls the changes back to main.

## Key Concepts
- **Main Branch = Planning HQ**
All features start here. Requirements and plans are created but not committed until the feature is complete.
- **Worktrees = Build Zones**
Each feature gets an isolated copy of your codebase. Changes are made here, then merged back.
- **One Task at a Time**
`/feature-build` implements tasks incrementally, pausing after each for review. This ensures quality and allows course correction.
- **Independent Merging**
Features merge independently. No waiting for other features to complete.


## How It Works
```
┌─────────────────────────────────────────────────────────────────────────┐
│                           MAIN BRANCH                                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                           │
│  │  START   │ >> │   PLAN   │ >> │   PREP   │                           │
│  │ /feature │    │ /feature │    │ /feature │                           │
│  │  -start  │    │  -plan   │    │  -prep   │                           │
│  └──────────┘    └──────────┘    └────┬─────┘                           │
│       │               │               │                                 │
│  Creates reqs.md  Creates plan.md     Creates tasks.md                  │
│                                       Creates worktree                  │
│                                       Opens VS Code                     │
└───────────────────────────────────────┼─────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         FEATURE WORKTREE                                │
│                                                                         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│  │  DOCKER  │    │   SEED   │    │  BUILD   │ >> │   END    │           │
│  │ /feature │    │ /feature │    │ /feature │    │ /feature │           │
│  │ -docker  │    │ -docker  │    │  -build  │    │   -end   │           │
│  │  start   │    │   seed   │    │          │    │          │           │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘           │
│       │               │               │               │                 │
│  Isolated env    Seed db with    Implements      Commits, merges        │
│  Unique ports    dev data        tasks 1-by-1    Cleans up worktree     │
│                                  Commits at                             |
|                                  key points                             |
└─────────────────────────────────────────────────────────────────────────┘
```

## Features
- **Parallel Development** - Plan multiple features on main, build in separate worktrees concurrently
- **Isolated Docker Environments** - Each feature runs with unique ports, preventing conflicts
- **AI-Assisted Implementation** - Claude Code helps implement tasks incrementally with review pauses
- **Commit Points** - Tasks are grouped with suggested commit points, so you know when to commit
- **Structured Documentation** - Requirements, plans, and tasks organized per feature
- **Database Seeding** - Copy data from main for realistic testing in feature environments
- **Conflict Resolution** - Guided workflow for merge conflicts with continuation support

## Quick Start
### Prerequisites
- Claude Code (via terminal or VS Code Extension)
- Git with worktree support
- Docker Desktop
- VS Code with [`code` command installed](https://code.visualstudio.com/docs/setup/mac#_configure-the-path-with-vs-code)

### Installation
```bash
git clone https://github.com/your-username/claude-flow.git
```

#### Global Install (recommended)
Install once, use in any project:

```bash
./claude-flow/setup.sh --global
```

Commands are installed to `~/.claude/commands/` and available in all projects.

#### Project Install
Install to a specific project only:

```bash
./claude-flow/setup.sh /path/to/your/project

# Or from within the project directory:
./claude-flow/setup.sh .
```

This copies commands to the project's `.claude/commands/`, creates `work/features/`, and updates `.gitignore`.

**For Docker features**: Ensure you have a `docker-compose.yml` with standard ports

### Basic Workflow
```bash
# On main branch - plan your feature
/feature-start "add user authentication"
# → Creates work/features/user-authentication/reqs.md

/feature-plan
# → Creates plan.md with implementation approach

/feature-prep
# → Creates worktree and tasks.md
# → Opens new VS Code window

# In new VS Code window (worktree)
/feature-docker start
# → Starts isolated Docker environment

/feature-docker seed
# → Seeds database from main

/feature-build
# → Implements tasks one-by-one with pauses for review

/feature-end
# → Commits, merges to main, cleans up
```

## Commands Reference
| Command | Location | Description |
|---------|----------|-------------|
| `/feature-start "description"` | Main | Create requirements document |
| `/feature-plan [name]` | Main | Create implementation plan |
| `/feature-prep [name]` | Main | Generate tasks, create worktree, open VS Code |
| `/feature-build` | Worktree | Implement tasks incrementally |
| `/feature-commit` | Worktree | Commit progress with context-aware message |
| `/feature-docker <action>` | Worktree | Manage Docker environment |
| `/feature-end` | Worktree | Commit, merge, cleanup |
| `/feature-merge-continue` | Main | Continue after resolving conflicts |
| `/feature-review [name]` | Anywhere | Get quick status of the feature (summary, progress, etc) |
| `/claudeflow-extend [command]` | Anywhere | Initialize extension files for customization |
| `/feature-help [topic]` | Anywhere | Get help on any topic |

### Docker Actions
```bash
/feature-docker start    # Start containers with isolated ports
/feature-docker stop     # Stop containers (preserve data)
/feature-docker restart  # Restart containers
/feature-docker logs     # View container logs
/feature-docker ps       # Show container status
/feature-docker down     # Remove containers and data
/feature-docker seed     # Copy database from main
```

### Commit Points
During `/feature-prep`, tasks are grouped into logical units with commit points:

```markdown
### Data Layer
- [ ] TSK1: Create user schema
- [ ] TSK2: Add validation logic

📍 **Commit Point:** "Add user data model with validation"

### API Layer
- [ ] TSK3: Create user endpoints
- [ ] TSK4: Add error handling

📍 **Commit Point:** "Add user API endpoints"
```

During `/feature-build`, when you complete a task at a commit point, you'll see:
```
📍 COMMIT POINT REACHED
   Suggested: "Add user data model with validation"

→ Reply "continue", "commit", or give feedback.
```

Reply "commit" to run `/feature-commit`, which stages changes and creates a commit with the suggested message. This keeps your commits clean and logically organized.

## Customizing Commands
Claudeflow supports project-specific extensions that customize command behavior without modifying the base commands. This lets you add security reviews, linting requirements, custom template sections, and more.

```bash
# Initialize all extension files
/claudeflow-extend

# Or just specific ones
/claudeflow-extend plan
/claudeflow-extend build
```

This creates `.claude/claudeflow-extensions/` with extension files you can customize:

| Extension | Common Customizations |
|-----------|----------------------|
| `feature-plan.md` | Security review sections, compliance requirements, custom template sections |
| `feature-build.md` | Linting requirements, testing standards, pre-task checklists |
| `feature-end.md` | Pre-merge checks, commit message format, notification steps |

**Example: Adding security review to plans**

```markdown
# .claude/claudeflow-extensions/feature-plan.md

## Additional Template Sections

### Security Review
- Authentication/authorization changes
- Data encryption requirements
- Input validation approach
```

Extensions are project-specific and should be committed to your repo to share with your team.

## Project Structure
```
your-project/
├── .claude/
│   ├── commands/              # Slash command definitions
│   └── claudeflow-extensions/ # Project-specific customizations
├── work/
│   └── features/
│       └── feature-name/
│           ├── reqs.md     # Requirements
│           ├── plan.md     # Implementation plan
│           └── tasks.md    # Task breakdown
├── docker-compose.yml      # Standard Docker config
└── src/

your-project.worktrees/
└── feature-name/           # Isolated worktree
    ├── .claude/            # Symlinked from main
    ├── .env                # Symlinked from main
    ├── docker-compose.override.yml  # Port overrides
    └── .env.docker         # Docker-specific env vars
```

## Port Assignment
Each feature gets unique ports calculated from the feature name hash:

| Service | Main | Feature (example) |
|---------|------|-------------------|
| App | 3000 | 3007 |
| PostgreSQL | 5432 | 5439 |
| Redis | 6379 | 6386 |

This allows running multiple features simultaneously without conflicts.

## Documentation
- [Docker Setup Guide](DOCKER-SETUP-GUIDE.md) - Complete Docker configuration and troubleshooting
- [Database Seeding Reference](DATABASE-SEEDING-REFERENCE.md) - Seeding strategies and examples
- [Gitignored Files Reference](GITIGNORED-FILES-REFERENCE.md) - Symlink setup for shared configs

## Tips
- Use `/feature-help` anytime you need guidance
- Commands auto-detect feature names when only one exists
- Keep features small and focused for easier merging
- Seed your database for realistic testing
- Review after each task during `/feature-build`

## License
MIT

## FAQ
### Why did you make this? 
I was looking to solve the exact problems I wrote about in the intro for myself. After trying a few things, I landed on this specific combination of tools/techniques. It worked pretty well for me and perhaps others could find it useful too.

### Why this specific tool set (VS Code, Claude Code, Docker, Git Worktrees)?
I use Claude Code and it's great and it has easily customizable commands. I also use VS Code (and it's also great and has a great Claude Code Extension) and I needed *something* to open the feature's code with. I use Git Worktrees because it's the best way to isolate branches, and I use Docker because.. come on.

### Did you write this with Claude Code?
Absolutely.