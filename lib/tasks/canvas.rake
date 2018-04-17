$canvas_tasks_loaded ||= false
unless $canvas_tasks_loaded
$canvas_tasks_loaded = true

def log_time(name, &block)
  puts "--> Starting: '#{name}'"
  time = Benchmark.realtime(&block)
  puts "--> Finished: '#{name}' in #{time}"
  time
end

def parallel_processes
  processes = (ENV['CANVAS_BUILD_CONCURRENCY'] || Parallel.processor_count).to_i
  puts "working in #{processes} processes"
  processes
end

namespace :canvas do
  desc "Compile javascript and css assets."
  task :compile_assets do |t, args|

    # opt out
    npm_install = ENV["COMPILE_ASSETS_NPM_INSTALL"] != "0"
    compile_css = ENV["COMPILE_ASSETS_CSS"] != "0"
    build_styleguide = ENV["COMPILE_ASSETS_STYLEGUIDE"] != "0"
    build_webpack = ENV["COMPILE_ASSETS_BUILD_JS"] != "0"
    build_api_docs = ENV["COMPILE_ASSETS_API_DOCS"] != "0"

    if npm_install
      log_time('Making sure node_modules are up to date') {
        Rake::Task['js:yarn_install'].invoke
      }
    end

    raise "Error running gulp rev" unless system('yarn run gulp rev')

    if compile_css
      # public/dist/brandable_css/brandable_css_bundles_with_deps.json needs
      # to exist before we run handlebars stuff, so we have to do this first
      Rake::Task['css:compile'].invoke
    end

    require 'parallel'
    tasks = Hash.new

    if build_styleguide
      tasks["css:styleguide"] = -> {
        Rake::Task['css:styleguide'].invoke
      }
    end

    Rake::Task['js:build_client_apps'].invoke

    generate_tasks = []
    generate_tasks << 'i18n:generate_js' if build_webpack
    build_tasks = []
    if build_webpack
      # build dev bundles even in prod mode so you can debug with ?optimized_js=0 query string
      # (except for on jenkins where we set JS_BUILD_NO_UGLIFY anyway so there's no need for an unminified fallback)
      build_prod = ENV['RAILS_ENV'] == 'production' || ENV['USE_OPTIMIZED_JS'] == 'true' || ENV['USE_OPTIMIZED_JS'] == 'True'
      dont_need_dev_fallback = build_prod && ENV['JS_BUILD_NO_UGLIFY']
      build_tasks << 'js:webpack_development' unless dont_need_dev_fallback
      build_tasks << 'js:webpack_production' if build_prod
    end

    msg = "run " + (generate_tasks + build_tasks).join(", ")
    tasks[msg] = -> {
      if generate_tasks.any?
        Parallel.each(generate_tasks, in_processes: parallel_processes) do |name|
          log_time(name) { Rake::Task[name].invoke }
        end
      end

      if build_tasks.any?
        Parallel.each(build_tasks, in_threads: parallel_processes) do |name|
          log_time(name) { Rake::Task[name].invoke }
        end
      end
    }

    if build_api_docs
      tasks["Generate documentation [yardoc]"] = -> {
        Rake::Task['doc:api'].invoke
      }
    end

    times = nil
    real_time = Benchmark.realtime do
      times = Parallel.map(tasks, :in_processes => parallel_processes) do |name, lamduh|
        log_time(name) { lamduh.call }
      end
    end
    combined_time = times.reduce(:+)
    puts "Finished compiling assets in #{real_time}. parallelism saved #{combined_time - real_time} (#{real_time.to_f / combined_time.to_f * 100.0}%)"
  end

  desc "Just compile css and js for development"
  task :compile_assets_dev do
    ENV["COMPILE_ASSETS_NPM_INSTALL"] = "0"
    ENV["COMPILE_ASSETS_STYLEGUIDE"] = "0"
    ENV["COMPILE_ASSETS_API_DOCS"] = "0"
    Rake::Task['canvas:compile_assets'].invoke
  end

  desc "Load config/dynamic_settings.yml into the configured consul cluster"
  task :seed_consul => [:environment] do
    def load_tree(root, tree)
      tree.each do |node, subtree|
        key = [root, node].compact.join('/')
        if Hash === subtree
          load_tree(key, subtree)
        else
          Imperium::KV.put(key, subtree, cas: 0)
        end
      end
    end

    load_tree(nil, ConfigFile.load('dynamic_settings'))
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

namespace :db do
  desc "Shows pending db migrations."
  task :pending_migrations => :environment do
    migrations = CANVAS_RAILS5_1 ?
      ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths) :
      ActiveRecord::Base.connection.migration_context.migrations
    pending_migrations = ActiveRecord::Migrator.new(:up, migrations).pending_migrations
    pending_migrations.each do |pending_migration|
      tags = pending_migration.tags
      tags = " (#{tags.join(', ')})" unless tags.empty?
      puts '  %4d %s%s' % [pending_migration.version, pending_migration.name, tags]
    end
  end

  desc "Shows skipped db migrations."
  task :skipped_migrations => :environment do
    migrations = CANVAS_RAILS5_1 ?
      ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths) :
      ActiveRecord::Base.connection.migration_context.migrations
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
      migrations = CANVAS_RAILS5_1 ?
        ActiveRecord::Migrator.migrations(ActiveRecord::Migrator.migrations_paths) :
        ActiveRecord::Base.connection.migration_context.migrations
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

%w{db:pending_migrations db:skipped_migrations db:migrate:predeploy}.each do |task_name|
  Switchman::Rake.shardify_task(task_name, categories: ->{ Shard.categories })
end

end
