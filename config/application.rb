# Put this in config/application.rb
require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

module CanvasRails
  class Application < Rails::Application
    config.autoload_paths += [config.root.join('lib').to_s]
    $LOAD_PATH << config.root.to_s
    config.encoding = 'utf-8'
    require_dependency 'logging_filter'
    config.filter_parameters.concat LoggingFilter.filtered_parameters

    eval(File.read(File.expand_path("../shared_boot.rb", __FILE__)), binding, "config/shared_boot.rb", 1)
  end
end
