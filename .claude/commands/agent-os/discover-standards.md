# Discover Standards — Process Overview

This guide helps extract tribal knowledge from codebases into concise, documented standards. Here's the workflow:

## Key Steps

**Step 1: Focus Area** — Identify 3-5 major areas (frontend, backend, cross-cutting) and ask the user which to explore.

**Step 2: Analyze & Present** — Read 5-10 representative files, find unusual/opinionated/tribal patterns, present findings for selection.

**Step 3: Ask Why, Then Draft** — For each standard: ask clarifying questions → wait for response → draft → confirm. Process one at a time.

**Step 4: Create Files** — Place standards in `agent-os/standards/[folder]/`, confirm with user before creating.

**Step 5: Update Index** — Add entries to `agent-os/standards/index.yml` with descriptions.

**Step 6: Continue or Done** — Offer to explore another area or finish.

## Writing Rules

Standards must be scannable and concise:

- "Lead with the rule — state what to do first, explain why second"
- Use code examples over prose
- Avoid documenting the obvious
- One concept per standard
- Bullet points over paragraphs

## Critical Constraint

**Always use AskUserQuestion** when requesting user input. Never batch multiple questions upfront — complete the full ask → draft → confirm cycle for each standard before moving to the next.
