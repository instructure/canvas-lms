require "utf8_cleaner"
require "i18n"
require "sexp_processor"
require "ruby_parser"
require "json"

module I18nTasks
  require "i18n_tasks/hash_extensions"
  require "i18n_tasks/lolcalize"
  require "i18n_tasks/utils"
  require "i18n_tasks/i18n_import"

  require_relative "i18n_tasks/railtie" if defined?(Rails)
end
