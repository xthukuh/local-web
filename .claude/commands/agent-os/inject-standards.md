# Inject Standards Command Overview

The `/inject-standards` command injects relevant standards into your current context. It operates in two modes:

## Operation Modes

**Auto-Suggest Mode** analyzes your conversation to recommend applicable standards, while **Explicit Mode** directly injects specified standards when you provide arguments like `api/response-format` or `root/naming`.

## Key Process Steps

The command first determines which scenario applies: regular conversation work, skill creation, or planning/shaping. This classification drives how standards are formatted for your use case.

For auto-suggest workflows, the system reads an index file, analyzes your task context, and presents "typically 2-5 standards" focused on your work rather than overwhelming you with options.

## Injection Formatting

In **conversation scenarios**, standards content is read directly into your chat with clear section markers. For **skill and planning scenarios**, you choose between references (lightweight, stays synced) or copying full content (self-contained but static).

## Practical Guidance

Run this command early in tasks before implementation begins. When uncertain about context, the system asks for confirmation rather than assuming. Related skills from `.claude/skills/` are surfaced for awareness but never invoked automatically.

Explicit mode supports injecting entire folders, individual files, and root-level standards using reserved keyword syntax.
