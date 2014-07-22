# Put this in config/application.rb
require File.expand_path('../boot', __FILE__)

require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"

Bundler.require(:default, Rails.env) if defined?(Bundler)

module CanvasRails
  class Application < Rails::Application
    config.autoload_paths += [config.root.join('lib').to_s]
    $LOAD_PATH << config.root.to_s
    config.encoding = 'utf-8'
    require_dependency 'logging_filter'
    config.filter_parameters.concat LoggingFilter.filtered_parameters
    config.action_dispatch.rescue_responses['AuthenticationMethods::AccessTokenError'] = 401

    config.app_generators do |c|
      c.test_framework :rspec
      c.integration_tool :rspec
      c.performance_tool :rspec
    end

    eval(File.read(File.expand_path("../shared_boot.rb", __FILE__)), binding, "config/shared_boot.rb", 1)
  end
end
