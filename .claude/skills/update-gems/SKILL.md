---
name: update-gems
description: "Update Ruby gem dependencies in Canvas LMS using bundler. Runs bundle outdated to audit, bundle update --conservative for safe upgrades, syncs lockfiles, and commits per gem or gem group. Use when the user asks to update gems, run bundle update, upgrade dependencies, check outdated gems, update Gemfile, or resolve bundler version conflicts."
allowed-tools: Bash(BUNDLE_LOCKFILE=active bundle*), Bash(bundle *), Bash(git add*), Bash(git commit*), Bash(git diff*), Bash(git status*), Read, Grep, Glob, Edit
---

Update gems in Canvas LMS following these rules:

## Workflow

1. **Audit**: Run `BUNDLE_LOCKFILE=active bundle outdated` to find outdated gems. Keep this list in memory since it is a relatively slow command.
2. **Update**: Run `bundle update --conservative <gem_name>` to update individual gems.
3. **Sync lockfiles**: Run `bundle install` to ensure all lockfiles are in sync.
4. **Verify**: Check that `bundle install` exits cleanly with no errors. If `bundle update` or `bundle install` fails with a dependency conflict, read the error output to identify the conflicting constraint, then either update the blocking gem first or skip the gem and move on.
5. **Commit**: Commit with a message of `bundle update <gem_name>`. Check for changes in `Gemfile*.lock`, `Gemfile.d/*.lock`, and `gems/*/Gemfile*.lock`.

## General Rules

- Never touch `Gemfile*.lock` files directly.

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
