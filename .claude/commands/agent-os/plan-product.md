# Plan Product Command Documentation

This resource outlines a CLI command for establishing foundational product documentation through guided conversation. The process creates three key files in the `agent-os/product/` directory.

## Core Workflow

The command follows a structured six-step approach:

1. **Check existing documentation** — Determines whether `mission.md`, `roadmap.md`, or `tech-stack.md` already exist, offering options to start fresh, update specific files, or cancel.

2. **Gather product vision** — Collects information about the problem solved, target users, and unique differentiators through sequential questions.

3. **Establish roadmap** — Documents MVP features and post-launch planned features.

4. **Define tech stack** — Either adopts an existing organizational standard or captures project-specific technologies across frontend, backend, database, and other categories.

5. **Generate files** — Creates markdown documents organizing all collected information into structured templates.

6. **Confirm completion** — Provides user confirmation and notes that generated files integrate with other planning tools.

## Key Principles

The implementation emphasizes "lightweight" documentation gathering, asking one question at a time to avoid overwhelming users. The brief responses are acceptable, allowing documents to expand later as needed.
