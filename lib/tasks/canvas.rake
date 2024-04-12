# frozen_string_literal: true

require "rake/task_graph"
require "parallel"

$canvas_tasks_loaded ||= false
unless $canvas_tasks_loaded
  $canvas_tasks_loaded = true

  def log_time(name, &)
    puts "--> Starting: '#{name}'"
    time = Benchmark.realtime(&)
    puts "--> Finished: '#{name}' in #{time.round(2)}s"
    time
  end

  def parallel_processes
    processes = (ENV["CANVAS_BUILD_CONCURRENCY"] || Parallel.processor_count).to_i
    puts "working in #{processes} processes"
    processes
  end

  namespace :canvas do
    desc "Compile javascript and css assets."
    task :compile_assets do # rubocop:disable Rails/RakeEnvironment
      # running :environment as a prerequisite task is necessary even if we don't
      # need it for this task: forked processes (through Parallel) that invoke other
      # Rake tasks may require the Rails environment and for some reason, Rake will
      # not re-run the environment task when forked
      require_relative "../../config/environment" rescue nil

      # opt out
      npm_install = ENV["COMPILE_ASSETS_NPM_INSTALL"] != "0"
      build_api_docs = ENV["COMPILE_ASSETS_API_DOCS"] != "0"
      build_css = ENV["COMPILE_ASSETS_CSS"] != "0"
      build_styleguide = ENV["COMPILE_ASSETS_STYLEGUIDE"] != "0"
      build_i18n = ENV["RAILS_LOAD_ALL_LOCALES"] != "0"
      build_js = ENV["COMPILE_ASSETS_BUILD_JS"] != "0"
      write_brand_configs = ENV["COMPILE_ASSETS_BRAND_CONFIGS"] != "0"
      build_prod_js = ENV["RAILS_ENV"] == "production" || ENV["USE_OPTIMIZED_JS"] == "true" || ENV["USE_OPTIMIZED_JS"] == "True"
      # build dev bundles even in prod mode so you can debug with ?optimized_js=0
      # query string (except for on jenkins where we set SKIP_SOURCEMAPS anyway
      # so there's no need for an unminified fallback)
      build_dev_js = ENV["JS_BUILD_NO_FALLBACK"] != "1" && (!build_prod_js || ENV["SKIP_SOURCEMAPS"] != "1")

      batches = Rake::TaskGraph.draw do
        task "brand_configs:write" => ["js:gulp_rev"] if write_brand_configs
        task "css:compile" => ["js:gulp_rev"] if build_css
        task "css:styleguide" if build_styleguide
        task "doc:api" if build_api_docs
        task "js:yarn_install" if npm_install
        task "js:gulp_rev" => [
          ("js:yarn_install" if npm_install),
          ("i18n:generate_js" if build_i18n)
        ].compact

        if build_i18n
          task "i18n:generate_js" => [
            ("js:yarn_install" if npm_install)
          ].compact
        end

        if build_js && build_dev_js
          task "js:webpack_development" => ["js:gulp_rev"]
        end

        if build_js && build_prod_js
          task "js:webpack_production" => ["js:gulp_rev"]
        end
      end

      batch_times = []
      real_time = Benchmark.realtime do
        batches.each do |tasks|
          batch_times += Parallel.map(tasks, in_processes: parallel_processes) do |task|
            name, runner = if task.is_a?(Hash)
                             task.values_at(:name, :runner)
                           else
                             [task, -> { Rake::Task[task].invoke }]
                           end

            log_time(name, &runner)
          end
        end
      end

      combined_time = batch_times.sum

      puts(
        "Finished compiling assets in #{real_time.round(2)}s. " \
        "Parallelism saved #{(combined_time - real_time).round(2)}s " \
        "(#{(real_time.to_f / combined_time.to_f * 100.0).round(2)}%)"
      )
    end

    desc "Just compile css and js for development"
    task :compile_assets_dev do
      ENV["COMPILE_ASSETS_NPM_INSTALL"] = "0"
      ENV["COMPILE_ASSETS_STYLEGUIDE"] = "0"
      ENV["COMPILE_ASSETS_API_DOCS"] = "0"
      ENV["COMPILE_ASSETS_BRAND_CONFIGS"] = "0"
      Rake::Task["canvas:compile_assets"].invoke
    end

    desc "Upload source maps to Sentry"
    task :upload_sentry_sourcemaps, [:auth_token, :url, :org, :project, :version] do |_, args| # rubocop:disable Rails/RakeEnvironment
      missing_args = %i[auth_token url org project version].select { |k| args[k].blank? }
      raise "Arguments missing: #{missing_args}" unless missing_args.empty?

      sentry_cli_path = (ENV["SENTRY_CLI_GLOBAL"] == "1") ? "sentry-cli" : "yarn run sentry-cli"

      puts "--> Uploading source maps to Sentry at #{args.url}"
      system "SENTRY_AUTH_TOKEN=#{args.auth_token} SENTRY_URL=#{args.url} SENTRY_ORG=#{args.org} #{sentry_cli_path} " \
             "releases --project #{args.project} files #{args.version} upload-sourcemaps public/dist/ --ignore-file " \
             ".sentryignore --url-prefix '~/dist/'"
    end

    desc "Load config/dynamic_settings.yml into the configured consul cluster"
    task seed_consul: [:environment] do
      def load_tree(root, tree)
        tree.each do |node, subtree|
          key = [root, node].compact.join("/")
          if subtree.is_a?(Hash)
            load_tree(key, subtree)
          else
            Diplomat::Kv.put(key, subtree.to_s, { cas: 0 })
          end
        end
      end

      load_tree(nil, ConfigFile.load("dynamic_settings"))
    end

    desc "Initialize vault"
    task seed_vault: [:environment] do
      Canvas::Vault.api_client.sys.mount(Canvas::Vault.kv_mount, "kv", "Application secrets for canvas", {
                                           options: { version: 1 },
                                           config: {
                                             # In prod this is higher, but for dev, a low ttl is more useful
                                             default_lease_ttl: "10s"
                                           }
                                         })
    end
  end

  namespace :lint do
    desc "lint controllers for bad render json calls."
    task :render_json do
      output = `script/render_json_lint`
      exit_status = $?.exitstatus
      puts output
      if exit_status == 0
        puts "lint:render_json test succeeded"
      else
        raise "lint:render_json test failed"
      end
    end
  end

  namespace :db do
    desc "Shows pending db migrations."
    task pending_migrations: :environment do
      migrations = ActiveRecord::Base.connection.migration_context.migrations
      args = [:up, migrations, ActiveRecord::Base.connection.schema_migration]
      if $canvas_rails == "7.1"
        internal_metadata = ActiveRecord::InternalMetadata.new(ActiveRecord::Base.connection)
        args << internal_metadata
      end
      pending_migrations = ActiveRecord::Migrator.new(*args).pending_migrations
      pending_migrations.each do |pending_migration|
        tags = pending_migration.tags
        tags = " (#{tags.join(", ")})" unless tags.empty?
        puts "  %4d %s%s" % [pending_migration.version, pending_migration.name, tags]
      end
    end

    desc "Shows skipped db migrations."
    task skipped_migrations: :environment do
      migrations = ActiveRecord::Base.connection.migration_context.migrations
      args = [:up, migrations, ActiveRecord::Base.connection.schema_migration]
      if $canvas_rails == "7.1"
        internal_metadata = ActiveRecord::InternalMetadata.new(ActiveRecord::Base.connection)
        args << internal_metadata
      end
      skipped_migrations = ActiveRecord::Migrator.new(*args).skipped_migrations
      skipped_migrations.each do |skipped_migration|
        tags = skipped_migration.tags
        tags = " (#{tags.join(", ")})" unless tags.empty?
        puts "  %4d %s%s" % [skipped_migration.version, skipped_migration.name, tags]
      end
    end

    namespace :migrate do
      desc "Run all pending predeploy migrations"
      # TODO: this is being replaced by outrigger
      # rake db:migrate:tagged[predeploy].
      # When all callsites are migrated, this task
      # definition can be dropped.
      task predeploy: [:environment, :load_config] do
        migrations = ActiveRecord::Base.connection.migration_context.migrations
        migrations = migrations.select { |m| m.tags.include?(:predeploy) }
        args = [:up, migrations, ActiveRecord::Base.connection.schema_migration]
        if $canvas_rails == "7.1"
          internal_metadata = ActiveRecord::InternalMetadata.new(ActiveRecord::Base.connection)
          args << internal_metadata
        end
        ActiveRecord::Migrator.new(*args).migrate
      end
    end

    namespace :test do
      desc "Drop and regenerate the test db by running migrations"
      task reset: [:environment, :load_config] do
        raise "Run with RAILS_ENV=test" unless Rails.env.test?

        config = ActiveRecord::Base.configurations.find_db_config("test")
        queue = config.configuration_hash[:queue]
        ActiveRecord::Tasks::DatabaseTasks.drop(queue) if queue rescue nil
        ActiveRecord::Tasks::DatabaseTasks.drop(config) rescue nil
        ActiveRecord::Base.connection_handler.clear_all_connections!
        Shard.default(reload: true) # make sure we know that sharding isn't set up yet
        CanvasCassandra::DatabaseBuilder.config_names.each do |cass_config|
          db = CanvasCassandra::DatabaseBuilder.from_config(cass_config)
          db.tables.each do |table|
            db.execute("DROP TABLE #{table}")
          end
        end
        ActiveRecord::Tasks::DatabaseTasks.create(queue) if queue
        ActiveRecord::Tasks::DatabaseTasks.create(config)
        ActiveRecord::Base.connection.schema_cache.clear!
        ActiveRecord::Base.descendants.each(&:reset_column_information)
        Rake::Task["db:migrate"].invoke
      end
    end
  end

  %w[db:pending_migrations db:skipped_migrations db:migrate:predeploy db:migrate:tagged].each do |task_name|
    Switchman::Rake.shardify_task(task_name)
  end

end
