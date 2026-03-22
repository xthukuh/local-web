# Shape Spec Command Overview

The **Shape Spec** is a CLI command for structuring planning before significant work begins. Key points:

## Core Requirements

- Must run in **plan mode** only
- Uses the `AskUserQuestion` tool for all user interactions
- Follows a 9-step structured process

## The 9-Step Process

1. **Clarify scope** — Understand what's being built
2. **Gather visuals** — Collect mockups or references
3. **Identify patterns** — Find similar code in the codebase
4. **Check product context** — Align with product goals if available
5. **Surface standards** — Identify applicable guidelines
6. **Generate folder name** — Create timestamped directory like `2026-01-15-1430-feature-slug/`
7. **Structure the plan** — Present task breakdown with spec documentation as Task 1
8. **Complete the plan** — Build out remaining implementation tasks
9. **Ready for execution** — Get user approval to proceed

## Output Deliverables

The command creates `agent-os/specs/{folder}/` containing:

- **plan.md** — Complete execution plan
- **shape.md** — Decisions and context captured during shaping
- **standards.md** — Applicable standards with full content
- **references.md** — Pointers to similar implementations
- **visuals/** — Optional mockups or screenshots

## Key Principle

"Task 1 always being 'Save spec documentation'" ensures shaping work is preserved before implementation begins, making future reference possible.
