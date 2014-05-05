require "i18n_extraction"
require "compass"
require "sass/plugin"

module HandlebarsTasks
  require "handlebars_tasks/handlebars"
  require "handlebars_tasks/ember_hbs"

  require_relative "handlebars_tasks/railtie" if defined?(Rails) && CANVAS_RAILS3
end
