$canvas_tasks_loaded ||= false
unless $canvas_tasks_loaded
$canvas_tasks_loaded = true

def log_time(name, &block)
  puts "--> Starting: '#{name}'"
  time = Benchmark.realtime(&block)
  puts "--> Finished: '#{name}' in #{time}"
  time
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

  desc "Compile javascript and css assets."
  task :compile_assets, :generate_documentation, :check_syntax, :compile_styleguide, :build_js do |t, args|
    # :check_syntax is currently a dummy argument that isn't used.
    args.with_defaults(:generate_documentation => true, :check_syntax => false, :compile_styleguide => true, :build_js => true)
    truthy_values = [true, 'true', '1']
    generate_documentation = truthy_values.include?(args[:generate_documentation])
    compile_styleguide = truthy_values.include?(args[:compile_styleguide])
    build_js = truthy_values.include?(args[:build_js])

    if ENV["COMPILE_ASSETS_NPM_INSTALL"] != "0"
      log_time('Making sure node_modules are up to date') {
        Rake::Task['js:npm_install'].invoke
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

    log_time("gulp rev") { Rake::Task['js:gulp_rev'].invoke }
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

%w{db:pending_migrations db:skipped_migrations db:migrate:predeploy}.each do |task_name|
  Switchman::Rake.shardify_task(task_name, categories: ->{ Shard.categories })
end

end
