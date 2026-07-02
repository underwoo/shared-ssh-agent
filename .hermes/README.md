# .hermes/ Directory

This directory contains Hermes AI assistant context and project management files.

## Purpose

These files help Hermes quickly understand project state when starting new sessions, preventing context window bloat by providing concise summaries instead of reconstructing state from chat history.

## Files

### current_phase.txt
One-line project status. Update when major milestones complete.

### next_steps.md
Actionable TODO list. Checkboxes for completed items.

### decisions.md
Architectural decisions, design rationale, and trade-offs. Explains WHY things are the way they are.

### plans/
Future enhancement plans (not yet implemented). See `plan` skill for format.

## Usage

**Starting a new Hermes session:**
```
Read .hermes/current_phase.txt and .hermes/next_steps.md to understand project state.
```

**During work:**
Update these files as you complete tasks or make decisions.

**Project handoff:**
These files serve as living documentation for future maintainers (human or AI).

## Maintenance

- Keep current_phase.txt under 2 lines
- Keep next_steps.md focused on near-term work
- Add to decisions.md when making non-obvious choices
- Git-track these files (they're project documentation)
