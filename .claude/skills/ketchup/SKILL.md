---
name: ketchup
description: Rebuild context after /clear by analyzing uncommitted changes across Canvas LMS and all plugin repositories
disable-model-invocation: true
argument-hint: [optional: "commits" to include committed changes]
---

I just cleared context. Help me ketchup by analyzing all uncommitted changes.

## Repository Changes

The script has gathered git status and diffs from the Canvas LMS main repository and all plugin subrepositories. Here's all the data:

!`.claude/skills/ketchup/get-diffs.sh $ARGUMENTS`

## Your Task

Analyze the repository changes above and provide a comprehensive summary:

### 1. Identify What's Being Worked On
Based on the nature of changes across all repositories, infer:
- What feature or task is being implemented
- The scope and purpose of the changes
- Any patterns (e.g., refactoring, bug fix, new feature, test updates)

### 2. Assess Progress
Determine if the changes are:
- Complete and ready for commit
- In progress with more work needed
- Just started/exploratory

### 3. Key Files and Locations
List the most important files being modified with their paths and relevant line numbers.
For example: `app/models/user.rb:45-67`

### 4. Likely Next Steps
Based on incomplete work or patterns in the changes, suggest what the developer might work on next.

### 5. Committed vs Uncommitted (if applicable)
If commit information was requested and included, note which changes are already committed in addition 
to still uncommitted.

## Analysis Guidelines

- **Focus on actual code changes**, not just filenames
- **Consider relationships** between changes (e.g., model + controller + view + test)
- **Look for TODOs or incomplete implementations** in the diffs
- **Identify missing pieces** (e.g., tests for new features, migrations for schema changes)
- **Be specific** with file paths and line numbers when referencing code
- **Keep the summary concise** but comprehensive

## Important Notes

- The get-diffs.sh script handles all git operations without consuming tokens
- It works from any directory within Canvas LMS (main repo or plugin subdirectory)
- Plugin repositories under `gems/plugins/*` are separate git repositories
- By default, only uncommitted changes are analyzed
- Pass "commits" or "committed" in $ARGUMENTS to also analyze recent commits

## Example Usage

- `/ketchup` - Analyzes only uncommitted changes
- `/ketchup commits` - Analyzes both uncommitted changes and recent commits
- `/ketchup some changes have been committed` - Also includes commit analysis
