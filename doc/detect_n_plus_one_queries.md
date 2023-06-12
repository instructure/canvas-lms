# Detect N+1 Queries

Canvas uses the [prosopite](https://github.com/charkost/prosopite) gem to detect N+1 query problems and prints information about them to `log/development.log` in development, and to `log/test.log` in test. It also prints this information to its own dedicated log file, `log/prosopite.log` when in development. Here's an example report:

```ruby
N+1 queries detected:
  SELECT "context_external_tools".* FROM "public"."context_external_tools" WHERE "context_external_tools"."id" = 1 LIMIT 1
  SELECT "context_external_tools".* FROM "public"."context_external_tools" WHERE "context_external_tools"."id" = 1 LIMIT 1
  SELECT "context_external_tools".* FROM "public"."context_external_tools" WHERE "context_external_tools"."id" = 1 LIMIT 1
  SELECT "context_external_tools".* FROM "public"."context_external_tools" WHERE "context_external_tools"."id" = 1 LIMIT 1
Call stack:
  config/initializers/postgresql_adapter.rb:315:in `exec_query'
  app/models/content_tag.rb:283:in `content'
  app/models/assignment.rb:3504:in `quiz_lti?'
  app/models/assignment.rb:394:in `can_duplicate?'
  lib/api/v1/assignment.rb:193:in `assignment_json'
  lib/api/v1/assignment_group.rb:82:in `block in assignment_group_json'
  lib/api/v1/assignment_group.rb:75:in `map'
  lib/api/v1/assignment_group.rb:75:in `assignment_group_json'
  ...<more stack trace>
```

In production, the gem can only be used via the `Prosopite.scan` method (the use case being testing some code for N+1s in a Rails Console).

## Prosopite.scan

You can pass a block to `Prosopite.scan` to have it check for N+1 queries:

```ruby
Prosopite.scan do
  Course.where(id: 1..5).each { |course| course.assignments.first }
end

N+1 queries detected:
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 4 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 1 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 2 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 3 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
Call stack:
  config/initializers/postgresql_adapter.rb:315:in `exec_query'
  (irb):5:in `block (2 levels) in <main>'
  (irb):5:in `block in <main>'
  (irb):4:in `<main>'

```

If you don't want to pass a block, you can use `Prosopite.scan` along with `Prosopite.finish`:

```ruby
Prosopite.scan
Course.where(id: 1..5).each { |course| course.assignments.first }
foo = "bar"
Prosopite.finish
N+1 queries detected:
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 4 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 1 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 2 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
  SELECT "assignments".* FROM "public"."assignments" WHERE "assignments"."context_id" = 3 AND "assignments"."context_type" = 'Course' ORDER BY assignments.created_at LIMIT 1
Call stack:
  config/initializers/postgresql_adapter.rb:315:in `exec_query'
  (irb):5:in `block in <main>'
  (irb):5:in `<main>'
```

## Enabling Detection

Automatic N+1 detection for requests is off by default. Setting the N_PLUS_ONE_DETECTION environment variable to 'true' causes all controller actions to be wrapped in a `Prosopite.scan` while in `development` or `test`. It also causes all rspec tests to be wrapped in a `Prosopite.scan`.

You can manually invoke `Prosopite.scan` in any environment, even when the N_PLUS_ONE_DETECTION environment variable is not set to 'true'.
