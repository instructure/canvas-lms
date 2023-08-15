# Teams config

This directory contains team configuration for Sentry error ownership.

The CanvasErrors library uses the `code_ownership` gem to compare exception
stack traces to the `owned_globs` in these YAML files. If a match is found,
the Sentry error is tagged with the team, like `inst.team:vice`

See [this Sentry filter](https://sentry.insops.net/organizations/instructure/issues/?project=28&query=is%3Aunresolved+inst.team%3Avice&referrer=issue-list&statsPeriod=14d) for an example of errors tagged for the VICE team.
And see `vice.yml` as an example YAML config.

## Adding a new team

Create a new YAML file in this directory, like `myteam.yml`, with contents like:

```yaml
# In myteam.yml

name: myteam # This is what the Sentry tag value will be
owned_globs:
  # Note the globs follow the ruby Dir.glob syntax:
  # https://ruby-doc.org/3.2.2/Dir.html#method-c-glob
  - "app/models/my_model/**/*"
  - "lib/gems/my_gem/**/*"
```
