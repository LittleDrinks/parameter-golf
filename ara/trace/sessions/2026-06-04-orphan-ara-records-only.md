# 2026-06-04 Orphan ARA records-only branch

## Goal

Create a records-only branch that does not inherit the `main` branch tree or history.

## Branch

```text
ara-records-only
```

This branch is an orphan root commit. It should contain only lightweight research/orchestration material:

```text
AGENTS.md
CLAUDE.md
ara/
skills/
.codex/skills/
agent-prompts/
```

It intentionally excludes project source and dependency trees such as:

```text
README.md
LICENSE
lmms-eval/
configs/
scripts/
*.py training/eval files
run_*.sh
requirements.txt
```

## Rationale

The previous `ara-records-clean` branch was created from `main`, so GitHub still displayed all normal project files. That is useful for a normal feature branch but wrong for a pure ARA records branch. The correct structure is an orphan branch whose root tree contains only records and project-level skills.
