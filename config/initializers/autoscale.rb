# Provides better configuration for auto-scaling dynos on Heroku
# than the out of the box options. See:
# https://devcenter.heroku.com/articles/rails-autoscale
require 'rails_autoscale_agent' if ENV['RAILS_AUTOSCALE_URL']

