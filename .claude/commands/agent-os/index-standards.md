# Index Standards — Process Overview

**Core Purpose:**
The index file (`index.yml`) enables the `/inject-standards` command to suggest relevant standards efficiently by maintaining a mapped catalog of descriptions rather than scanning all files.

## Key Workflow Steps

1. **Scan** — Identify all `.md` files in `agent-os/standards/` and subfolders, using "root" as the folder designation for files directly in the standards directory

2. **Load** — Read the existing `index.yml` to identify current entries

3. **Compare** — Detect new files, deleted entries, and unchanged standards

4. **Index New Files** — For each new standard, read its content and propose a brief description via user confirmation

5. **Prune Stale Entries** — Remove index references to deleted files without requiring approval

6. **Generate Updated Index** — Produce `index.yml` using alphabetized folders and files, formatted as:
   ```yaml
   folder-name:
     file-name:
       description: Single sentence summary
   ```

7. **Report Changes** — Summarize additions, removals, and unchanged counts

## Important Notes

- Descriptions must be one sentence, used for matching purposes
- "root" is reserved for standards files in `agent-os/standards/` directly (not an actual folder)
- `/discover-standards` automatically triggers this process, so manual runs are typically unnecessary unless indexes are out of sync
