require 'rubygems'
require 'daemons'
require 'optparse'

module Delayed
  class Command
    attr_accessor :worker_count, :process_name
    
    def initialize(args)
      @files_to_reopen = []
      @options = {:quiet => true}
      
      @worker_count = 1
      
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"

        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-e', '--environment=NAME', 'Specifies the environment to run this delayed jobs under (test/development/production).') do |e|
          STDERR.puts "The -e/--environment option has been deprecated and has no effect. Use RAILS_ENV and see http://github.com/collectiveidea/delayed_job/issues/#issue/7"
        end
        opts.on('--min-priority N', 'Minimum priority of jobs to run.') do |n|
          @options[:min_priority] = n
        end
        opts.on('--max-priority N', 'Maximum priority of jobs to run.') do |n|
          @options[:max_priority] = n
        end
        opts.on('-n', '--number_of_workers=workers', "Number of unique workers to spawn") do |worker_count|
          @worker_count = worker_count.to_i rescue 1
        end
        opts.on('-p', '--process-name=NAME', "The name to append to the process name. eg. delayed_job_NAME") do |process_name|
          @process_name = process_name
        end
        opts.on('-q', '--queue=QUEUE_NAME', "The name of the queue for the workers to pull work from") do |queue|
          @options[:queue] = queue
        end
      end
      @args = opts.parse!(args)
    end
  
    def daemonize
      ObjectSpace.each_object(File) do |file|
        @files_to_reopen << file unless file.closed?
      end
      
      worker_count.times do |worker_index|
        base_name =  @process_name ? "delayed_job_#{@process_name}" : "delayed_job"
        process_name = worker_count == 1 ? base_name : "#{base_name}.#{worker_index}"
        Daemons.run_proc(process_name, :dir => "#{RAILS_ROOT}/tmp/pids", :dir_mode => :normal, :ARGV => @args) do |*args|
          run process_name
        end
      end
    end
    
    def run(worker_name = nil)
      Dir.chdir(RAILS_ROOT)
      
      # Re-open file handles
      @files_to_reopen.each do |file|
        begin
          file.reopen File.join(RAILS_ROOT, 'log', 'delayed_job.log'), 'a+'
          file.sync = true
        rescue ::Exception
        end
      end
      
      ActiveRecord::Base.connection.reconnect!
      
      worker = Delayed::Worker.new(@options)
      worker.name_prefix = "#{worker_name} "
      worker.start
    rescue => e
      Rails.logger.fatal e
      STDERR.puts e.message
      exit 1
    end
    
  end
end
