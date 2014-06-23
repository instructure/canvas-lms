require 'i18n_tasks'
module I18nTasks
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../tasks/i18n.rake", __FILE__)
    end
  end
end