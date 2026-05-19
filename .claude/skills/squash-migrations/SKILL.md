---
name: squash-migrations
description: Guidelines for squashing old Canvas database migrations
allowed-tools: Bash(pg_dump*), Bash(git diff*), Bash(git status*), Bash(ls *), Bash(git mv *), Bash(git rm *), Edit, Glob, Grep, Read, Write
---

Squashing migrations is the process of going through individual migrations in `db/migrate` by date, and "squashing" them into the `InitCanvasDb` migration, then deleting the original.
Canvas' policy is that we squash migrations quarterly, with a one quarter lag. In other words, migrations from Q1 are squashed beginning in Q3. Do one month's worth of migration per commit, to ease review complexity.
Plugins in `gems/plugins/*/db/migrate` might also have migrations that need squashed into a base migration for that plugin, similar to `InitCanvasDb`. Plugin migrations use a single commit for the entire quarter, since they rarely have migrations.

## Rules

- `change_table` blocks that add new structures can be moved into the corresponding `create_table` block.
- Individual DDL statements such as `add_index`, `add_reference`, etc. should also be moved to the corresponding `create_table` block, and modified as appropriate if their arguments differ.
- `remove_`-style statements should result in the removal of the corresponding `add_`-style structure from `InitCanvasDb`.
  Check the model file for any removed columns, and if the column has been ignored there, remove it from the list.
  Remove the `ignored_columns` line completely if the list is empty.
- `create_table` blocks should be moved into `InitCanvasDb` completely, putting it into its properly alphabetized position (using the non-plural form of the table name, so that for example `discussion_topics` is placed before `discussion_topic_replies`)
- `set_replication_identity` calls are moved into the `SetReplicaIdenties` migration, in their same alphabetized position.
- Any options (such as `algorithm: :concurrently`, `if_not_exists: true`, `validate: false`, `validate_constraint`) used to make the original migration idempotent are not necessary in `InitCanvasDb`, and should be removed.
- Options that are already the default should not be specified:
  - `default: nil`
  - `null: true`
  - `index: true` on `t.references` calls
  - `index: false` on non-reference column addition calls
- Keep the statements within `create_table` blocks organized, with a blank line between each section:
  - Column additions (including `t.timestamps`) are the first section, preserving their original order they were added
  - Additional constraints are the next section, preserving their original order they were added
  - Additional indexes are the final section, preserving their original order they were added, with the exception that the `t.replica_identity_index` is first.
- If the migration queues a `DataFixup`, find the file defining it, and any associated spec file. If the DataFixup is not referenced by any other migration, just delete the spec file, the `DataFixup` file, and the migration file.
- `create_initial_partitions` calls can be squashed into the `CreateInitialPartitions` migration.

## Validation Process

Before making any modifications, reset the test database and store a baseline:

```bash
RAILS_ENV=test bin/rake db:test:reset
pg_dump -s --restrict-key=MQTD3FxKJiJ5XiNN2cfyqy9ctUI0Tt9i3SWn8wZ7l2dYLJGctear9gqS1IRbdO5 canvas_test > original.sql
```

After making modifications, reset the test database again, dump it, and confirm no structural changes:

```bash
RAILS_ENV=test bin/rake db:test:reset
pg_dump -s --restrict-key=MQTD3FxKJiJ5XiNN2cfyqy9ctUI0Tt9i3SWn8wZ7l2dYLJGctear9gqS1IRbdO5 canvas_test > modified.sql
diff -u original.sql modified.sql
```

The diff output should be empty. Exceptions are allowed if the order of columns has changed because a squashed column is now earlier in the table than a column added by a migration in `gems/plugins/*/db/migrate/*.`

## Finishing Up

- Alter `ValidateMigrationIntegrity` by replacing the timestamp in `last_squashed_migration_version` with the value from the last deleted migration, and increment the version number in the filename.
- Run `script/rlint -a` to fix any formatting issues.
