require 'compass-rails'
require 'sass/plugin'

Sass::Plugin.options[:never_update] = !Rails.env.development?
