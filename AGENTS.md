# Project instructions

## Before editing

1. Read `CODING-STANDARDS.md` before changing any repository file. Apply every relevant rule and use its linked feature documentation as the source of truth.
2. Read the `quickshell` skill for every Quickshell or QML task. Verify APIs and framework behavior against the official Quickshell and Qt QML documentation linked there.
3. Read the `quickshell-ui` skill before changing a visible surface, including its layout, styling, typography, icons, clipping, empty states, or motion.

The reading step is complete when you can name the relevant project rules and documentation for the planned change without guessing.

## Implementation

- Apply YAGNI. Build the smallest documented design that satisfies the current requirement. Remove accidental complexity instead of preserving it, and add no machinery for hypothetical needs.
- Prefer Quickshell-native APIs. If the documentation shows no native solution, explain the proposed alternative and get the maintainer's approval before editing.
- Confirm constraints in the current code and documentation before deciding how to implement a change. Ask the maintainer when those sources leave a decision ambiguous.
- Apply SOLID when it reduces coupling or clarifies ownership. Prefer a direct, focused component over an abstraction that exists only to demonstrate a pattern.
- Apply DRY when a third copy would otherwise be introduced. Do not create an abstraction for one or two uses unless it clarifies ownership or removes meaningful complexity.
- Write comments that explain how a function or non-obvious mechanism is used. Keep comments with the code they describe and let clear bindings and structure explain routine behavior.
- Use POSIX-compatible `sh` for shell commands and scripts, including `['sh', '-c', ...]` when a shell invocation is required.
- Keep code, comments, and commit messages free of user-specific or environment-specific details such as network names, device names, usernames, hostnames, and absolute home paths.

## Conflicts

When a project rule conflicts with the requested work, stop before editing. Name the rule, explain the conflict, and get explicit maintainer approval for the exception.
