require 'compass-rails'

Sass::Plugin.options[:never_update] = !Rails.env.development?
