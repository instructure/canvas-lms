require 'handlebars_tasks'
module HandlebarsTasks
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../tasks/jst.rake", __FILE__)
    end
  end
end