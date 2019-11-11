# Make sure we log to stdout for compatibility with Heroku's logging infrastructure.
# This also helps with static assets, but I'm focused on logging right now so I don't know
# the implications there.
gem 'rails_12factor', group: :production

# Structured JSON logging to stdout.
gem "logjam_agent", github: "beyond-z/logjam_agent"

# Performance tuning halp!
# See: https://devcenter.heroku.com/articles/scout
gem 'scout_apm', require: false
