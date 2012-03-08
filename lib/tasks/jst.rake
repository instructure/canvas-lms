require 'lib/handlebars/handlebars'

namespace :jst do
  desc 'precompile handlebars templates from app/views/jst to public/javascripts/jst'
  task :compile do
    require 'config/initializers/plugin_symlinks'

    Handlebars.compile 'app/views/jst', 'public/javascripts/jst'
    Dir[Rails.root+'app/views/jst/plugins/*'].each do |input_path|
      plugin = input_path.sub(%r{.*app/views/jst/plugins/}, '')
      output_path = "public/plugins/#{plugin}/javascripts/jst"
      Handlebars.compile input_path, output_path, plugin
    end
  end
end

