# Make sure we log to stdout for compatibility with Heroku's logging infrastructure.
# This also helps with static assets, but I'm focused on logging right now so I don't know
# the implications there.
gem 'rails_12factor', group: :production

# Allows us to write rake tasks that can programatticaly run Heroku commands
# using their API. E.g. create a task to restart a dyno so it can be run
# in the middle of the night to avoid a 30 second delay while the app boots 
# (if running a single dyno which we are at the time of writing)
# See: https://github.com/heroku/platform-api
gem 'platform-api', require: false

# Structured JSON logging to stdout.
gem "logjam_agent", github: "beyond-z/logjam_agent"

# Performance tuning halp!
# See: https://devcenter.heroku.com/articles/scout
gem 'scout_apm', require: false

# Provides better configuration for auto-scaling dynos on Heroku
# than the out of the box options. See:
# See: https://elements.heroku.com/addons/rails-autoscale
gem 'rails_autoscale_agent'  # NOTE: don't use require false. It doesn't work to load in initializer for some reason.
