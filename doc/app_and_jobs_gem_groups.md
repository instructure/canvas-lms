# App and Jobs Gem Groups

Canvas runs two distinct server types from the same codebase: **app servers** (handling HTTP requests via Apache/Passenger in Production) and **jobs servers** (processing background jobs via `script/delayed_job`). The `:app_server` and `:jobs_server` Bundler groups (located in Gemfile.d/jobs_server.rb and Gemfile.d/app_server.rb) allow each server type to load only the gems it needs, reducing memory usage.

## How It Works

In `config/application.rb`, Bundler loads gems using the `Bundler.require(*Rails.groups)` statement. By default, [`Rails.groups`](https://api.rubyonrails.org/classes/Rails.html#method-c-groups) includes:

- `:default`, which means all gems in the default group (i.e. when no group is specified) are included
- The environment, e.g. `"development"` in a dev environment, or `"production"` in a production environment. This means all gems in the group corresponding with the current environment will be included.

For example, in a development rails console you would see:

```ruby
> Rails.groups
=> [:default, "development"]
```

In addition, the `RAILS_GROUPS` environment variable can be set to include additional groups. For example, to include the :jobs_server gem group:

```bash
RAILS_GROUPS=jobs_server bundle exec rails console
> Rails.groups
=> [:default, "development", "jobs_server"]
```

This `RAILS_GROUPS` env var is how we conditionally load these app and jobs groups.

## Automatic Group Inference

Regardless of environment, the correct gem group is automatically inferred based on the server type. In config/boot.rb we set `RAILS_GROUPS` to `"jobs_server"` for job servers, and to `"app_server"` for app servers. We identify jobs servers using the `RUNNING_AS_DAEMON` env var that is set in `script/delayed_job`. We identify app servers using the `RUNNING_IN_RACK` env var that is set in config.ru.

If `RAILS_GROUPS` is set in the environment before starting, it is used as-is and the automatic inference is skipped. This allows you to override the default behavior when needed.

## When to Add a Gem to a Group

**Add to `:jobs_server`** if every call site for a gem is reachable only via a background job mechanism:

- `.delay(...).<method>`
- `handle_asynchronously :<method>`
- `Delayed::Job.enqueue(...)`
- `Delayed::Periodic.cron(...)`
- A worker class implementing `perform`

**Add to `:app_server`** if every call site is reachable only via a synchronous HTTP request.

**Leave in the default group if:**

- It is used by both server types
- You are unsure — the default is always safe
- It is Rails infrastructure or a shared utility called from both contexts

When in doubt, trace each call site back to its entry point before deciding. Also note that calls to `delay_if_production(...).<method>` should be treated as synchronous for this purpose; this code will run on app servers in development environments, and therefore any gems used within these calls need to be available on both app and jobs servers.

## Verifying a Change

You can verify that a gem is loaded in one env, and not loaded in another, by executing a `rails runner` command with the `RAILS_GROUPS` env var set. For example, after adding the `mimemagic` gem to `Gemfile.d/jobs_server.rb`, you can run:

```sh
# Prints nil — not loaded on app server
DISABLE_SPRING=1 RAILS_GROUPS=app_server bundle exec rails runner "puts defined?(MimeMagic).inspect"
nil

# Prints "constant" — loaded on jobs server
DISABLE_SPRING=1 RAILS_GROUPS=jobs_server bundle exec rails runner "puts defined?(MimeMagic).inspect"
"constant"
```

Alternatively, you can run canvas locally, and put a `puts` or `debugger` statement within app & jobs code and then check for the gem's existence.
