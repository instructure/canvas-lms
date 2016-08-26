$canvas_tasks_loaded ||= false
unless $canvas_tasks_loaded
$canvas_tasks_loaded = true

def log_time(name, &block)
  puts "--> Starting: '#{name}'"
  time = Benchmark.realtime(&block)
  puts "--> Finished: '#{name}' in #{time}"
  time
end

def check_syntax(files)
  quick = ENV["quick"] && ENV["quick"] == "true"
  puts "--> Checking Syntax...."
  show_stoppers = []
  raise "jsl needs to be in your $PATH, download from: javascriptlint.com" if `which jsl`.empty?
  puts "--> Found jsl..."

  Array(files).each do |js_file|
    js_file.strip!
    # only lint things in public/javascripts that are not in /vendor, /compiled, etc.
    if js_file.match /public\/javascripts\/(?!vendor|compiled|i18n.js|InstUI.js|translations|old_unsupported_dont_use_react)/
      file_path = File.join(Rails.root, js_file)

      unless quick
        # to use this, you need to have jshint installed from npm
        # (which means you need to have node.js installed)
        # on osx you can do:
        # brew install node
        # npm install jshint
        unless `which jshint`.empty?
          puts " --> Checking #{js_file} using JSHint:"
          js_hint_errors = `jshint #{file_path} --config "#{File.join(Rails.root, '.jshintrc')}"`
          puts js_hint_errors
        end

        # Checks for coding style problems using google's js style guide.
        # Only works if you have gjslint installed.
        # Download from http://code.google.com/closure/utilities/
        unless `which gjslint`.empty?
          puts " --> Checking #{js_file} using gjslint.py:"
          gjslint_errors = `gjslint --nojsdoc --strict #{js_file}`
          puts gjslint_errors = gjslint_errors.split("\n").reject{ |l| l.match("Line too long") }.join("\n")
        end
      end

      jsl_output = `jsl -process "#{file_path}" -nologo -conf "#{File.join(Rails.root, 'config', 'jslint.conf')}"`
      exit_status = $?.exitstatus
      if exit_status != 0
        puts " --> Error checking #{js_file} using jsl:"
        if jsl_output.match("warning: trailing comma is not legal in ECMA-262 object initializers") || jsl_output.match("extra comma is not recommended in array initializers")
          exit_status = 2
          jsl_output << "fatal trailing comma found. Stupid IE!"
        end
        if exit_status >= 2
          show_stoppers << jsl_output
        end
        puts jsl_output
      end
    end
  end
  if show_stoppers.empty?
    puts " --> No JavaScript errors found using jsl"
  else
    raise "FATAL JavaScript errors found using jsl"
  end
end


namespace :canvas do
  desc "Compresses static assets"
  task :compress_assets do
    assets = FileList.new('public/**/*.js', 'public/**/*.css')
    before_bytes = 0
    after_bytes = 0
    processed = 0
    assets.each do |asset|
      asset_compressed = "#{asset}.gz"
      unless File.exists?(asset_compressed)
        `gzip --best --stdout "#{asset}" > "#{asset_compressed}"`
        before_bytes += File::Stat.new(asset).size
        after_bytes += File::Stat.new(asset_compressed).size
        processed += 1
      end
    end
    puts "Compressed #{processed} assets, #{before_bytes} -> #{after_bytes} bytes (#{"%.0f" % ((before_bytes.to_f - after_bytes.to_f) / before_bytes * 100)}% reduction)"
  end

  task :check_syntax  => "canvas:check_syntax:all"
  namespace :check_syntax do
    desc "Checks all js files that are staged for commiting to git for syntax errors. Make your .git/hooks/pre-commit look like: rake canvas:check_syntax:changed quick=true to not allow committing js with syntax errors"
    task :changed do
      files = `git diff-index --name-only --cached HEAD -- | grep '\.js$'`
      check_syntax(files)
    end

    desc "Checks all js files for sytax errors."
    task :all do
      #bundles = YAML.load(ERB.new(File.read('config/assets.yml')).result)['javascripts']
      files = (Dir.glob('./public/javascripts/*.js')).
        reject{ |file| file =~ /\A\.\/public\/javascripts\/(i18n.js|translations\/)/ }

      check_syntax(files)
    end
  end

  desc "Compile javascript and css assets."
  task :compile_assets, :generate_documentation, :check_syntax, :compile_styleguide, :build_js do |t, args|
    args.with_defaults(:generate_documentation => true, :check_syntax => false, :compile_styleguide => true, :build_js => true)
    truthy_values = [true, 'true', '1']
    generate_documentation = truthy_values.include?(args[:generate_documentation])
    check_syntax = truthy_values.include?(args[:check_syntax])
    compile_styleguide = truthy_values.include?(args[:compile_styleguide])
    build_js = truthy_values.include?(args[:build_js])

    if ENV["COMPILE_ASSETS_NPM_INSTALL"] != "0"
      log_time('Making sure node_modules are up to date') {
        raise 'error running npm install' unless `npm install`
      }
    end

    if ENV["COMPILE_ASSETS_CSS"] != "0"
      # public/dist/brandable_css/brandable_css_bundles_with_deps.json needs
      # to exist before we run handlebars stuff, so we have to do this first
      Rake::Task['css:compile'].invoke
    end

    require 'parallel'
    processes = (ENV['CANVAS_BUILD_CONCURRENCY'] || Parallel.processor_count).to_i
    puts "working in #{processes} processes"

    tasks = Hash.new

    if compile_styleguide
      tasks["css:styleguide"] = -> {
        Rake::Task['css:styleguide'].invoke
      }
    end

    # TODO: Once webpack is the only way, remove js:build
    if build_js
      tasks["compile coffee, js 18n, run r.js optimizer, and webpack"] = -> {
        prereqs = ['js:generate', 'i18n:generate_js']
        prereqs.each do |name|
          log_time(name) { Rake::Task[name].invoke }
        end
        # webpack and js:build can run concurrently
        Parallel.each(['js:build', 'js:webpack'], :in_threads => processes.to_i) do |name|
          log_time(name) { Rake::Task[name].invoke }
        end
      }
    else
      tasks["compile coffee"] = -> {
        ['js:generate'].each do |name|
          log_time(name) { Rake::Task[name].invoke }
        end
      }
    end

    if check_syntax
      tasks["check JavaScript syntax"] = -> {
        Rake::Task['canvas:check_syntax'].invoke
      }
    end

    if generate_documentation
      tasks["Generate documentation [yardoc]"] = -> {
        Rake::Task['doc:api'].invoke
      }
    end

    times = nil
    real_time = Benchmark.realtime do
      times = Parallel.map(tasks, :in_processes => processes.to_i) do |name, lamduh|
        log_time(name) { lamduh.call }
      end
    end
    combined_time = times.reduce(:+)
    puts "Finished compiling assets in #{real_time}. parallelism saved #{combined_time - real_time} (#{real_time.to_f / combined_time.to_f * 100.0}%)"
    raise "Error reving files" unless system('node_modules/.bin/gulp rev')
  end

  desc "Check static assets and generate api documentation."
     task :check_static_assets do
       threads = []
       threads << Thread.new do
         puts "--> JS tests"
         Rake::Task['js:test'].invoke
       end

       threads << Thread.new do
         puts "--> i18n check"
         Rake::Task['i18n:check'].invoke
       end

       threads << Thread.new do
         puts "--> Check syntax"
         Rake::Task['canvas:check_syntax'].invoke
       end

       threads << Thread.new do
         puts "--> Generating API documentation"
         Rake::Task['doc:api'].invoke
       end
     threads.each(&:join)
   end
end

namespace :lint do
  desc "lint controllers for bad render json calls."
  task :render_json do
    output = `script/render_json_lint`
    exit_status = $?.exitstatus
    puts output
    if exit_status != 0
      raise "lint:render_json test failed"
    else
      puts "lint:render_json test succeeded"
    end
  end
end

if CANVAS_RAILS4_0
  old_task = Rake::Task['db:_dump']
  old_actions = old_task.actions.dup
  old_task.actions.clear

  old_task.enhance do
    if ActiveRecord::Base.dump_schema_after_migration == false
      # do nothing
    else
      old_actions.each(&:call)
    end
  end
end

namespace :db do
  desc "Shows pending db migrations."
  task :pending_migrations => :environment do
    migrations = ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths)
    pending_migrations = ActiveRecord::Migrator.new(:up, migrations).pending_migrations
    pending_migrations.each do |pending_migration|
      tags = pending_migration.tags
      tags = " (#{tags.join(', ')})" unless tags.empty?
      puts '  %4d %s%s' % [pending_migration.version, pending_migration.name, tags]
    end
  end

  desc "Shows skipped db migrations."
  task :skipped_migrations => :environment do
    migrations = ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths)
    skipped_migrations = ActiveRecord::Migrator.new(:up, migrations).skipped_migrations
    skipped_migrations.each do |skipped_migration|
      tags = skipped_migration.tags
      tags = " (#{tags.join(', ')})" unless tags.empty?
      puts '  %4d %s%s' % [skipped_migration.version, skipped_migration.name, tags]
    end
  end

  namespace :migrate do
    desc "Run all pending predeploy migrations"
    task :predeploy => [:environment, :load_config] do
      migrations = ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths)
      migrations = migrations.select { |m| m.tags.include?(:predeploy) }
      ActiveRecord::Migrator.new(:up, migrations).migrate
    end
  end

  namespace :test do
    desc "Drop and regenerate the test db by running migrations"
    task :reset => [:environment, :load_config] do
      raise "Run with RAILS_ENV=test" unless Rails.env.test?
      config = ActiveRecord::Base.configurations['test']
      queue = config['queue']
      ActiveRecord::Tasks::DatabaseTasks.drop(queue) if queue rescue nil
      ActiveRecord::Tasks::DatabaseTasks.drop(config) rescue nil
      Canvas::Cassandra::DatabaseBuilder.config_names.each do |cass_config|
        db = Canvas::Cassandra::DatabaseBuilder.from_config(cass_config)
        db.tables.each do |table|
          db.execute("DROP TABLE #{table}")
        end
      end
      ActiveRecord::Tasks::DatabaseTasks.create(queue) if queue
      ActiveRecord::Tasks::DatabaseTasks.create(config)
      ::ActiveRecord::Base.connection.schema_cache.clear!
      ::ActiveRecord::Base.descendants.each(&:reset_column_information)
      Rake::Task['db:migrate'].invoke
    end
  end
end

Switchman::Rake.filter_database_servers do |servers, block|
  if ENV['REGION']
    if ENV['REGION'] == 'self'
      servers.select!(&:in_current_region?)
    else
      servers.select! { |server| server.in_region?(ENV['REGION']) }
    end
  end
  block.call(servers)
end

%w{db:pending_migrations db:skipped_migrations db:migrate:predeploy}.each { |task_name| Switchman::Rake.shardify_task(task_name) }

end
