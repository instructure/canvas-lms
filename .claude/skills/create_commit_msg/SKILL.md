---
name: create_commit_msg
description: Help create a well-formatted git commit message following Canvas LMS conventions
disable-model-invocation: true
---

# Create Commit

Help create a well-formatted git commit message following Canvas LMS conventions.

## Format Requirements

**Title line** (required):
- Maximum 60 characters
- Concise summary of the change
- Imperative mood (e.g., "Fix bug" not "Fixed bug")

**Body** (required for non-trivial changes):
- Each line maximum 60 characters
- Explain WHY the change was made
- Include technical details and context
- Describe what was changed (if not obvious from title)
- Keep it concise but detailed
- Avoid redundant information

**Ticket reference** (required):
- Use `refs TICKET-ID` for general work
- Use `Fixes TICKET-ID` for bug fixes
- Use `closes TICKET-ID` for completing features
- If ticket is unknown, prompt user for it

**Feature flag** (required):
- Use `flag=flag_name` if a feature flag is involved
- Use `flag=none` if no flag is needed

**Test plan** (required):
- Include manual testing steps for QA
- Focus on user-facing verification steps
- Be specific about expected results
- Include different scenarios/edge cases
- Don't mention automated tests (always implied)

## Instructions for Claude

⚠️ **CRITICAL: NEVER AUTOMATICALLY COMMIT** ⚠️
- This command ONLY generates the commit message
- DO NOT run `git commit` or any commit commands
- ONLY display the message to the user
- ALWAYS ask for explicit confirmation before committing
- Wait for user approval before taking any git actions
- **Each invocation requires NEW explicit approval** — prior
  approval in the same session does NOT carry over. Even if
  the user approved a commit earlier in this conversation,
  you MUST ask again for each new invocation of this command.

When the user invokes this command:

1. **Gather information**:
   - Review ONLY staged changes: `git diff --staged`
   - Check staged files: `git status`
   - DO NOT look at unstaged changes (`git diff` without
     `--staged`) — only staged content is being committed
   - **If nothing is staged, stop immediately** and tell
     the user there is nothing to commit
   - Identify what was changed and why
   - If ticket number or feature flag is unknown, ask
     for BOTH in a single message (not separately)

2. **Generate commit message**:
   - Title: 60 chars max, imperative mood
   - Body: 60 chars per line, explain the "why"
   - Include technical details and context
   - Add ticket reference (refs/Fixes/closes)
   - Add flag reference (flag=name or flag=none)
   - Create detailed test plan with manual steps

3. **Format**:
   ```
   Short title (max 50 chars)

   Body paragraph explaining the change. Each line max
   65 chars. Explain why this change was needed and what
   it fixes or improves.

   Additional context about the implementation if needed.
   Break into multiple paragraphs for readability.

   Changes:
   - Bullet point summary of key changes (optional)
   - Keep bullets concise but informative
   - Focus on what, not how

   refs TICKET-1234
   flag=feature_flag_name

   Test plan:
   Setup:
   - Setup step 1
   - Setup step 2

   Testing:
   - Test step 1 with expected result
   - Test step 2 with expected result
   - Verify edge case X
   - Verify edge case Y

   Expected Results:
   - Clear description of what should happen
   ```

4. **Display message and get approval**:
   - Show the complete generated commit message in a code block
   - DO NOT commit anything at this stage
   - Ask: "Would you like me to commit these changes with
     this message?"
   - If user says yes, THEN run the git commit command
     using a heredoc to preserve formatting:
     ```
     git commit -m "$(cat <<'EOF'
     Title here

     Body here
     EOF
     )"
     ```
   - NEVER use `--no-verify` to skip hooks
   - If user requests changes, regenerate the message
   - NEVER commit without explicit user confirmation

## Example (Generic)

```
Add validation for email input field

Email addresses were not being validated before submission,
allowing invalid formats to be saved to the database. This
caused downstream errors in notification systems.

Added client-side validation using regex pattern and
server-side validation in the controller. Invalid emails
now show an error message and prevent form submission.

Changes:
- Add email format validation to user form
- Add server-side validation in UsersController
- Display error message for invalid email format
- Add validation tests for edge cases

refs COURSE-1234
flag=none

Test plan:
Setup:
- Navigate to user profile edit page as any user role

Testing:
- Enter valid email (user@example.com) and verify it saves
- Enter invalid email (notanemail) and verify error appears
- Enter email without @ symbol and verify error appears
- Enter email without domain and verify error appears
- Try submitting form with invalid email via console
- Verify server rejects invalid email with proper error
- Test with very long email address (255+ chars)
- Verify email validation works for new user creation

Expected Results:
- Valid emails save successfully without errors
- Invalid emails show clear error message and block save
- Server validation prevents bypassing client validation
- Error messages are clear and actionable
```

## Command Workflow

1. User invokes `/create_commit_msg`
2. Claude reviews ONLY staged changes (`git diff --staged`)
3. Claude asks for ticket number (if needed)
4. Claude asks about feature flags (if needed)
5. Claude generates and displays the commit message
6. **Claude asks: "Would you like me to commit with this
   message?"**
7. User reviews and approves OR requests changes
8. Only after approval: Claude runs git commit command

**Important**: Steps 1-6 MUST complete before any git commit
command is executed. The user must explicitly approve.

## Notes

- Keep commit messages focused on one logical change
- If changes are unrelated, create separate commits
- Test plan should be thorough but realistic for QA
- Include accessibility testing when UI changes are made
- Specify browser/environment requirements if relevant
