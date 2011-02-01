require 'rubygems'
require 'daemons'

# The config/delayed_jobs.yml file has a format like:
#
# production:
#   workers:
#   - queue: normal
#     workers: 2
#     max_priority: 10
#   - queue: normal
#     workers: 2
# 
# default:
#   workers:
#   - queue: normal
#     workers: 5
#   - periodic: config/periodic_jobs.rb
#
# If a "periodic" worker is not specified, rufus-scheduler is not required

module Delayed
  class Pool
    attr_accessor :workers

    def self.run
      if GC.respond_to?(:copy_on_write_friendly=)
        GC.copy_on_write_friendly = true
      end
      self.new(Rails.root+"config/delayed_jobs.yml").daemonize
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end

    def initialize(config_filename)
      @workers = {}
      config = YAML.load_file(config_filename)
      @config = (environment && config[environment]) || config['default']
      # Backwards compatibility from when the config was just an array of queues
      @config = { :workers => @config } if @config.is_a?(Array)
      @config = @config.with_indifferent_access
      unless @config && @config.is_a?(Hash)
        raise ArgumentError,
          "Invalid config file #{config_filename}"
      end
    end

    def environment
      RAILS_ENV
    end

    def daemonize
      @files_to_reopen = []
      ObjectSpace.each_object(File) do |file|
        @files_to_reopen << file unless file.closed?
      end
      Daemons.run_proc('delayed_jobs_pool',
                       :dir => "#{RAILS_ROOT}/tmp/pids",
                       :dir_mode => :normal) do
        Dir.chdir(RAILS_ROOT)
        # Re-open file handles
        @files_to_reopen.each do |file|
          begin
            file.reopen File.join(RAILS_ROOT, 'log', 'delayed_job.log'), 'a+'
            file.sync = true
          rescue ::Exception
          end
        end

        ActiveRecord::Base.connection.disconnect!

        start
        join
      end
    end

    def start
      spawn_all_workers
      say "**** started master at PID: #{Process.pid}"
    end

    def join
      begin
        loop do
          child = Process.wait
          if child
            worker = delete_worker(child)
            say "**** child died: #{child}, restarting"
            spawn_worker(worker.config)
          end
        end
      rescue Errno::ECHILD
      end
      say "**** all children killed. exiting"
    end

    def spawn_all_workers
      @config[:workers].each do |worker_config|
        worker_config = worker_config.with_indifferent_access
        (worker_config[:workers] || 1).times { spawn_worker(worker_config) }
      end
    end

    def spawn_worker(worker_config)
      if worker_config[:queue]
        worker_config[:max_priority] ||= nil
        worker_config[:min_priority] ||= nil
        worker = Delayed::PoolWorker.new(worker_config)
      elsif worker_config[:periodic]
        worker = Delayed::PeriodicChildWorker.new(worker_config)
      else
        raise "invalid worker type in config: #{worker_config}"
      end

      pid = fork do
        ActiveRecord::Base.connection.reconnect!
        worker.start
      end
      workers[pid] = worker
    end

    def delete_worker(child)
      worker = workers.delete(child)
      return worker if worker
      say "whoaaa wtf this child isn't known: #{child}"
    end

    def say(text, level = Logger::INFO)
      if logger
        logger.add level, "#{Time.now.strftime('%FT%T%z')}: #{text}"
      else
        puts text
      end
    end

  end

  module ChildWorker
    # must be called before forking
    def initialize(*args)
      @parent_pid = Process.pid
      super
    end

    def exit?
      super || parent_exited?
    end

    private

    def parent_exited?
      @parent_pid && @parent_pid != Process.ppid
    end
  end

  class PoolWorker < Delayed::Worker
    include ChildWorker
  end

  class PeriodicChildWorker < Delayed::PeriodicWorker
    include ChildWorker
  end
end
