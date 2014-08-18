require "i18n_extraction"
require "compass"
require "sass/plugin"

require "handlebars_tasks/handlebars"
require "handlebars_tasks/ember_hbs"
require "handlebars_tasks/railtie" if defined?(Rails) && CANVAS_RAILS3
