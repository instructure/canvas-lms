---
name: update-gems
description: Update Ruby gem dependencies
allowed-tools: Bash(BUNDLE_LOCKFILE=active bundle*), Bash(bundle *), Bash(git add*), Bash(git commit*), Bash(git diff*), Bash(git status*), Read, Grep, Glob, Edit
---

Update gems in Canvas LMS following these rules:

## General Rules

- Never touch `Gemfile*.lock` files directly
- Run `BUNDLE_LOCKFILE=active bundle outdated` to find the list of outdated gems.
  Keep this list in memory so you don't have to keep running it, since it is a relatively slow command.
- Run `bundle update --conservative <gem_name>` to update individual gems
- Run `bundle install` one more time to ensure all lockfiles are in sync
- Commit the changes, with a commit message of `bundle update <gem_name>` (you don't need to include the conservative flag in the commit message).
  Be sure to check for changes in `Gemfile*.lock`, `Gemfile.d/*.lock`, and `gems/*/Gemfile*.lock`.

## Gem Groups

Some groups of gems can be updated together:
- `aws*`
- `google*`
- Rails: `action*`, `active*`, `rack*`, `rails`, `railties`, and `zeitwerk` -- except `active_model_serializers`
- `datadog` and its dependencies that aren't shared with other gems, such as `libdatadog`
- `faraday*`
- `redis*`
- `rspec*`
- `rubocop*` (and their dependencies that aren't shared with other gems, such as `ast`)
- `ruby-lsp*`
- `sentry*`

All other gems should be updated and committed independently.
The commit message for a group should use the base name without the wildcard, or `rails` for the Rails group.

## Additional Rules

- Look in `Gemfile.lock` to determine a gem's dependencies — they're indented one level deeper than the gem that depends on them in each `specs` section.
- Don't attempt to update any gems that already have an exact version requirement on them.
- Don't bother updating `sorbet-runtime` for patch version changes.
- Do the rubocop group last, after all other groups and individual gems, since it will likely have new offenses that will need to be resolved.
- If the gem is referenced by any file in `gems/plugins/*/*.gemspec` with an exact pin, it will need to be updated by changing the exact pin in the gemspec, then running `BUNDLE_LOCKFILE=active bundle install`.
  You still need to run a bare `bundle install` afterwards to ensure the main lockfile and any child lockfiles stay in sync.
