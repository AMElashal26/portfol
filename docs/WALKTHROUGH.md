# Portfol — Architecture Walkthrough

> How the whole system fits together, for when you're reading the code or explaining it to someone.

## The Big Picture

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR TERMINAL SESSION                     │
│                                                             │
│  You build something cool ──→ plog "what I built"           │
│                                    │                        │
│                                    ▼                        │
│  ┌──────────────────────────────────────────────┐           │
│  │  bin/portfol.sh (the dispatcher)             │           │
│  │  Reads the command, routes to the right file  │           │
│  └──────────┬───────────────────────────────────┘           │
│             │ sources                                        │
│             ▼                                                │
│  ┌──────────────────────────────────────────────┐           │
│  │  lib/log.sh                                   │           │
│  │  1. Generates build ID (b_20260326_001)      │           │
│  │  2. Finds recently modified files             │           │
│  │  3. Detects skills from file extensions       │           │
│  │  4. Writes JSONL to ~/.portfol/builds.jsonl   │           │
│  └──────────┬───────────────────────────────────┘           │
│             │ appends                                        │
│             ▼                                                │
│  ┌──────────────────────────────────────────────┐           │
│  │  ~/.portfol/builds.jsonl (your build log)     │           │
│  │  One JSON object per line. Grows over time.   │           │
│  └──────────────────────────────────────────────┘           │
│                                                             │
│  Later: portfol generate / reverse / stats                  │
│  These READ builds.jsonl and PRODUCE content in outputs/    │
└─────────────────────────────────────────────────────────────┘
```

## File Map

### The Repo (~/Developer/portfol/) — Version-Controlled Code

```
~/Developer/portfol/
│
├── bin/
│   └── portfol.sh          ← THE ENTRY POINT
│                              When you type `portfol`, this runs.
│                              It's a "dispatcher" — reads the command name
│                              and routes to the right lib/ file.
│
├── lib/
│   ├── utils.sh             ← THE TOOLBOX
│   │                          Colors, paths, helper functions.
│   │                          Every other file imports this.
│   │                          Change a path here → it changes everywhere.
│   │
│   ├── log.sh               ← PHASE 0 (working now)
│   │                          Logs builds with auto-detection.
│   │                          The most important command.
│   │
│   ├── list.sh              ← PHASE 0 (working now)
│   │                          Lists all your builds in a table.
│   │
│   ├── show.sh              ← PHASE 0 (working now)
│   │                          Shows details of one specific build.
│   │
│   ├── stats.sh             ← PHASE 0 (basic), PHASE 4 (full)
│   │                          Skill frequency chart now.
│   │                          Trending, gaps, suggestions later.
│   │
│   ├── generate.sh          ← PHASE 2 (stub)
│   │                          Will call Claude CLI to transform
│   │                          builds into LinkedIn posts, resume
│   │                          bullets, and Upwork gig listings.
│   │
│   └── reverse.sh           ← PHASE 3 (stub)
│                              Will read job descriptions and match
│                              them against your builds, finding gaps
│                              and generating tailored content.
│
├── templates/
│   ├── resume-bullet.md     ← Prompt template for resume bullets
│   ├── linkedin-post.md     ← Prompt template for LinkedIn posts
│   ├── upwork-gig.md        ← Prompt template for gig listings
│   ├── reverse-project.md   ← Prompt template for job matching
│   ├── linkedin-profile.md  ← Prompt template for profile rewrites
│   │
│   └── examples/
│       ├── good-bullets.md  ← Few-shot examples of GOOD resume bullets
│       ├── bad-bullets.md   ← Anti-patterns to AVOID
│       └── tone-samples.md  ← Writing samples that match your voice
│
├── config/
│   └── config.example.json  ← Template for user config
│                              Gets copied to ~/.portfol/config.json
│                              on `portfol init`
│
├── docs/
│   ├── WALKTHROUGH.md       ← YOU ARE HERE
│   └── plans/               ← Implementation plans for each phase
│
└── .gitignore               ← Tells git what NOT to track
```

### Your Data (~/.portfol/) — Private, NOT on GitHub

```
~/.portfol/
│
├── builds.jsonl             ← THE MASTER LOG
│                              Every build you log goes here.
│                              One JSON object per line (JSONL format).
│                              This is the source of truth for everything.
│
├── config.json              ← YOUR PROFILE
│                              Name, target roles, tone preferences.
│                              Gets injected into every prompt template.
│
├── outputs/
│   ├── linkedin-posts/      ← Generated LinkedIn posts (one .md per build)
│   ├── resume-bullets/      ← Generated resume bullets
│   ├── upwork-gigs/         ← Generated Upwork listings
│   └── reverse-projects/    ← Job description analysis results
│
└── job-descriptions/        ← Saved job descriptions for reverse mode
```

## How Data Flows

### 1. Logging a Build

```
You type: plog "Built a screenshot routing pipeline"
     │
     ▼
portfol.sh reads "log" → sources lib/log.sh → calls portfol_log()
     │
     ▼
_log_quick() runs:
     │
     ├── generate_build_id()  → "b_20260326_002"
     │
     ├── find ~/Developer ... -mmin -120
     │   → discovers 5 recently modified files
     │
     ├── Checks file extensions (.sh, .py, .json)
     │   → infers skills: "Shell Scripting", "Python"
     │
     ├── jq -cn builds a JSON object:
     │   {"id":"b_20260326_002","title":"Built a screenshot...","skills_demonstrated":["Python","Shell Scripting"],...}
     │
     └── echo >> ~/.portfol/builds.jsonl
         → appends that single line to the file
```

### 2. Generating Content (Phase 2 — Coming Soon)

```
You type: portfol generate resume-bullet
     │
     ▼
generate.sh will:
     │
     ├── Read the latest build from builds.jsonl
     │
     ├── Read the actual source code files listed in the build
     │
     ├── Load templates/resume-bullet.md
     │   (includes your good/bad examples as few-shot training)
     │
     ├── Load config.json for your name, tone, target roles
     │
     ├── Assemble everything into one prompt
     │
     ├── Call: claude -p "<assembled prompt>" --output-format json
     │
     └── Save the result to ~/.portfol/outputs/resume-bullets/b_20260326_002.md
```

### 3. Reverse Engineering (Phase 3 — Coming Soon)

```
You copy a job description → run: portfol reverse
     │
     ▼
reverse.sh will:
     │
     ├── Read clipboard with pbpaste
     │
     ├── Read ALL your builds from builds.jsonl
     │
     ├── Load templates/reverse-project.md
     │
     ├── Call Claude to:
     │   ├── Extract required skills from the JD
     │   ├── Match each skill against your builds
     │   ├── Rate matches: DIRECT / ADJACENT / GAP
     │   └── For gaps: suggest 2-4 hour projects to fill them
     │
     └── Save: tailored resume, cover letter, proposal, gap project ideas
```

## Key Concepts

### JSONL (JSON Lines)
One JSON object per line. Not an array. Each line is independent.
```
{"id":"b_001","title":"Built a thing","skills":["Python"]}
{"id":"b_002","title":"Automated a workflow","skills":["Shell"]}
```
Why not a JSON array? Because:
- **Append**: `echo '{}' >> file` (can't do this with an array)
- **Grep**: `grep "Python" file` finds relevant lines instantly
- **Stream**: Process one line at a time without loading the whole file
- **jq**: `jq '.' file` processes each line automatically

### The Dispatcher Pattern
One main script routes to sub-scripts. Like a receptionist:
```
You: "I need log"     → receptionist: "Go to lib/log.sh"
You: "I need stats"   → receptionist: "Go to lib/stats.sh"
You: "I need foo"     → receptionist: "I don't know that one, here's the help menu"
```

### source vs. bash
```bash
source lib/log.sh    # Runs IN the current shell (shares variables)
bash lib/log.sh      # Runs in a NEW shell (isolated, can't see our variables)
```
We use `source` because the lib files need access to utils.sh variables (colors, paths).

### "$@" vs. $*
```bash
"$@"  → preserves argument boundaries: "log" "--quick" "Built a thing" (3 args)
$*    → smashes everything together: "log" "--quick" "Built" "a" "thing" (5 args)
```
Always use `"$@"` when passing arguments through.

### Exit Codes
```bash
return 0    # Success (the universal "all good")
return 1    # Failure (something went wrong)
exit 0      # Same but kills the entire script, not just the function
exit 1      # Same but for errors
```
The `set -e` flag in portfol.sh means any non-zero return crashes the script,
which is why we use `|| true` or `|| echo 0` to handle expected failures.

## Phase Roadmap

| Phase | What It Does | Status |
|-------|-------------|--------|
| 0 | Repo + skeleton + log/list/show/stats | ✅ Done |
| 1 | `portfol generate` calls Claude CLI for real content | 📋 Next |
| 2 | `portfol reverse` reads job descriptions, matches builds | 📋 Planned |
| 3 | `portfol stats` with trending, gaps, suggestions | 📋 Planned |
| 4 | Git integration (`gc` wrapper auto-logs commits) | 📋 Planned |

## Your ~/.zshrc Aliases

```bash
portfol    → ~/Developer/portfol/bin/portfol.sh    # Full command
plog       → portfol log --quick                    # Quick log shortcut
prev       → portfol reverse                        # Reverse mode shortcut
pstats     → portfol stats                          # Stats shortcut
```
