# Make sure we log to stdout for compatibility with Heroku's logging infrastructure.
# This also helps with static assets, but I'm focused on logging right now so I don't know
# the implications there.
gem 'rails_12factor', group: :production

# The app times out on Heroku. Enabling New Relic to see if there are any quick insights.
# TODO: switch this over to Honeycomb or get approvale from team to use New Relic.
gem 'newrelic_rpm', group: :production

# Structured JSON logging to stdout.
gem "logjam_agent", github: "beyond-z/logjam_agent"
