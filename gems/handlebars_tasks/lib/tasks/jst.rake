namespace :jst do
  desc 'precompile handlebars templates from app/views/jst to public/javascripts/jst'
  task :compile do
    require 'handlebars_tasks'
    require 'config/initializers/plugin_symlinks'

    all_paths = []
    all_paths <<  ['app/views/jst', 'public/javascripts/jst']
    Dir[Rails.root+'app/views/jst/plugins/*'].each do |input_path|
      plugin = input_path.sub(%r{.*app/views/jst/plugins/}, '')
      output_path = "public/plugins/#{plugin}/javascripts/jst"
      all_paths << [input_path, output_path, plugin]
    end
    HandlebarsTasks::Handlebars.compile *all_paths
  end

  desc 'precompile ember templates'
  task :ember do
    require 'handlebars_tasks'
    files = Dir.glob("app/coffeescripts/**/*.hbs")
    files.each do |file|
      HandlebarsTasks::EmberHbs.compile_file(file)
    end
  end
end
