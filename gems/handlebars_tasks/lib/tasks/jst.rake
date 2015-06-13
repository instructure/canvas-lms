namespace :jst do
  def format_exception
    yield
  rescue HandlebarsTasks::CompilationError => e
    $stderr.puts "HBS PRECOMPILATION FAILED"
    $stderr.puts "#{e.path}:#{e.line}: #{e.message.gsub(/^/, '  ').lstrip}"
    exit 1
  end

  desc 'precompile handlebars templates from app/views/jst to public/javascripts/jst'
  task :compile do
    require 'handlebars_tasks'
    require 'config/initializers/plugin_symlinks'

    all_paths = []
    all_paths <<  ['app/views/jst', 'public/javascripts/jst']
    Dir['app/views/jst/plugins/*'].each do |input_path|
      plugin = input_path.sub(%r{.*app/views/jst/plugins/}, '')
      output_path = "public/plugins/#{plugin}/javascripts/jst"
      all_paths << [input_path, output_path, plugin]
    end

    format_exception do
      HandlebarsTasks::Handlebars.compile *all_paths
    end
  end

  desc 'precompile ember templates'
  task :ember do
    require 'handlebars_tasks'

    files = if ENV['file'].present?
      [ ENV['file'] ]
    else
      Dir.glob("app/coffeescripts/**/*.hbs")
    end

    format_exception do
      files.each do |file|
        HandlebarsTasks::EmberHbs.compile_file(file)
      end
    end
  end
end
