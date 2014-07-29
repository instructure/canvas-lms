require 'recaptcha/rails'
require_dependency 'canvas/plugin'

Rails.configuration.to_prepare do
  require_dependency 'users_controller_recaptcha'
  require_dependency 'register_recaptcha_plugin'
end
