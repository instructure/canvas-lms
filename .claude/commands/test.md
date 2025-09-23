---
description: Test the latest changes
allowed-tools: Read, Grep, Glob, Git
---

First view the latest uncommited changes in git with `git diff HEAD`, or if there are no uncommitted
changes, use `git show` to view the latest commit. Closely analyze the changes and determine what
test files are related to all of the changed code files. Run only those test files that are affected
by the most recent changes. Remember: changes may have downstream effects that need to be taken into
consideration. For example, an update to a model may change the REST API controller or the GraphQL
controller test results. You will need to find any files that are affected by the changes as test
them as well.
