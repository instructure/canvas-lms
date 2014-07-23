# Don't load rspec if running "rake gems:*"
unless Rails.env.production? || ARGV.any? { |a| a =~ /\Agems/ }

  begin
    require 'rspec/core/rake_task'
  rescue MissingSourceFile, LoadError
    module Spec
      module Rake
        class SpecTask
          include ::Rake::DSL

          def initialize(name)
            task name do
              # if rspec-rails is a configured gem, this will output helpful material and exit ...
              require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

              # ... otherwise, do this:
              raise <<-MSG

#{"*" * 80}
*  You are trying to run an rspec rake task defined in
*  #{__FILE__},
*  but rspec can not be found in vendor/gems, vendor/plugins or system gems.
#{"*" * 80}
              MSG
            end
          end
        end
      end
    end
  end

  Rake.application.instance_variable_get('@tasks').delete('default')

  task :default => :spec
  task :stats => "spec:statsetup"

  spec_files_attr = :pattern=
  klass = RSpec::Core::RakeTask

  desc "Run all specs in spec directory (excluding plugin specs)"
  klass.new(:spec) do |t|
    # you can also do SPEC_OPTS='-e "test name"' but this is a little easier I
    # suppose.
    if ENV['SINGLE_TEST']
      t.spec_opts += ['-e', %{"#{ENV['SINGLE_TEST']}"}]
    end
    spec_files = FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/**/*_spec.rb')
    Gem.loaded_specs.values.each do |spec|
      path = spec.full_gem_path
      spec_canvas_path = File.expand_path(path+"/spec_canvas")
      next unless File.directory?(spec_canvas_path)
      spec_files << spec_canvas_path
    end
    if ENV['IN_MEMORY_DB']
      N_PROCESSES = [ENV['IN_MEMORY_DB'].to_i, 1].max
      spec_files = spec_files.map { |x| Dir[x + "/[^selenium]**/*_spec.rb"] }.flatten.sort.in_groups_of(N_PROCESSES)
      processes = []
      Signal.trap "SIGINT", (lambda { Process.kill "-KILL", Process.getpgid(0) })
      child = false
      N_PROCESSES.times do |j|
        pid = Process.fork
        unless pid
          child = true
          t.send(spec_files_attr, spec_files.map { |x| x[j] }.compact)
          break
        end
        processes << pid
      end
      exit Process.waitall.map(&:last).map(&:exitstatus).count { |x| x != 0 } unless child
    else
      t.send(spec_files_attr, spec_files)
    end
  end

  namespace :spec do
    desc "Run all specs in spec directory, wiping the database first"
    task :wipedb do
      ENV["RAILS_ENV"] ||= "test"
      Rake::Task["db:test:prepare"].execute
      Rake::Task["spec"].execute
    end

    desc "Run non-selenium files in a single thread"
    klass.new(:single) do |t|
      require File.expand_path(File.dirname(__FILE__) + '/parallel_exclude')
      t.send(spec_files_attr, ParallelExclude::AVAILABLE_FILES)
    end

    desc "Print Specdoc for all specs (excluding plugin specs)"
    klass.new(:doc) do |t|
      t.spec_opts = ["--format", "specdoc", "--dry-run"]
      t.send(spec_files_attr, FileList['spec/**/*/*_spec.rb'])
    end

    desc "Print Specdoc for all plugin examples"
    klass.new(:plugin_doc) do |t|
      t.spec_opts = ["--format", "specdoc", "--dry-run"]
      t.send(spec_files_attr, FileList['vendor/plugins/**/spec/**/*/*_spec.rb'].exclude('vendor/plugins/rspec/*'))
    end

    [:models, :services, :controllers, :views, :helpers, :lib, :selenium].each do |sub|
      desc "Run the code examples in spec/#{sub}"
      klass.new(sub) do |t|
        t.spec_opts = ['--options', "\"#{Rails.root}/spec/spec.opts\""]
        t.send(spec_files_attr, FileList["spec/#{sub}/**/*_spec.rb"])
      end
    end

    desc "Run the code examples in vendor/plugins (except RSpec's own)"
    klass.new(:coverage) do |t|
      t.spec_opts = ['--options', "\"#{Rails.root}/spec/spec.opts\""]
      t.send(spec_files_attr, FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/**/*_spec.rb'))
    end

    namespace :plugins do
      desc "Runs the examples for rspec_on_rails"
      klass.new(:rspec_on_rails) do |t|
        t.spec_opts = ['--options', "\"#{Rails.root}/spec/spec.opts\""]
        t.send(spec_files_attr, FileList['vendor/plugins/rspec-rails/spec/**/*/*_spec.rb'])
      end
    end

    # Setup specs for stats
    task :statsetup do
      require 'code_statistics'
      ::STATS_DIRECTORIES << %w(Model\ specs spec/models) if File.exist?('spec/models')
      ::STATS_DIRECTORIES << %w(Service\ specs spec/services) if File.exist?('spec/services')
      ::STATS_DIRECTORIES << %w(View\ specs spec/views) if File.exist?('spec/views')
      ::STATS_DIRECTORIES << %w(Controller\ specs spec/controllers) if File.exist?('spec/controllers')
      ::STATS_DIRECTORIES << %w(Helper\ specs spec/helpers) if File.exist?('spec/helpers')
      ::STATS_DIRECTORIES << %w(Library\ specs spec/lib) if File.exist?('spec/lib')
      ::STATS_DIRECTORIES << %w(Routing\ specs spec/lib) if File.exist?('spec/routing')
      ::CodeStatistics::TEST_TYPES << "Model specs" if File.exist?('spec/models')
      ::CodeStatistics::TEST_TYPES << "Service specs" if File.exist?('spec/services')
      ::CodeStatistics::TEST_TYPES << "View specs" if File.exist?('spec/views')
      ::CodeStatistics::TEST_TYPES << "Controller specs" if File.exist?('spec/controllers')
      ::CodeStatistics::TEST_TYPES << "Helper specs" if File.exist?('spec/helpers')
      ::CodeStatistics::TEST_TYPES << "Library specs" if File.exist?('spec/lib')
      ::CodeStatistics::TEST_TYPES << "Routing specs" if File.exist?('spec/routing')
    end

    namespace :db do
      namespace :fixtures do
        desc "Load fixtures (from spec/fixtures) into the current environment's database.  Load specific fixtures using FIXTURES=x,y. Load from subdirectory in test/fixtures using FIXTURES_DIR=z."
        task :load => :environment do
          ActiveRecord::Base.establish_connection(Rails.env)
          base_dir = File.join(Rails.root, 'spec', 'fixtures')
          fixtures_dir = ENV['FIXTURES_DIR'] ? File.join(base_dir, ENV['FIXTURES_DIR']) : base_dir

          require 'active_record/fixtures'
          (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/).map { |f| File.join(fixtures_dir, f) } : Dir.glob(File.join(fixtures_dir, '*.{yml,csv}'))).each do |fixture_file|
            Fixtures.create_fixtures(File.dirname(fixture_file), File.basename(fixture_file, '.*'))
          end
        end
      end
    end

    namespace :server do
      daemonized_server_pid = File.expand_path("#{Rails.root}/tmp/pids/spec_server.pid")

      desc "start spec_server."
      task :start do
        if File.exist?(daemonized_server_pid)
          $stderr.puts "spec_server is already running."
        else
          $stderr.puts %Q{Starting up spec_server ...}
          FileUtils.mkdir_p('tmp/pids') unless test ?d, 'tmp/pids'
          system("ruby", "script/spec_server", "--daemon", "--pid", daemonized_server_pid)
        end
      end

      desc "stop spec_server."
      task :stop do
        unless File.exist?(daemonized_server_pid)
          $stderr.puts "No server running."
        else
          $stderr.puts "Shutting down spec_server ..."
          system("kill", "-s", "TERM", File.read(daemonized_server_pid).strip) &&
              File.delete(daemonized_server_pid)
        end
      end

      desc "restart spec_server."
      task :restart => [:stop, :start]

      desc "check if spec server is running"
      task :status do
        if File.exist?(daemonized_server_pid)
          $stderr.puts %Q{spec_server is running (PID: #{File.read(daemonized_server_pid).gsub("\n", "")})}
        else
          $stderr.puts "No server running."
        end
      end
    end
  end
end
