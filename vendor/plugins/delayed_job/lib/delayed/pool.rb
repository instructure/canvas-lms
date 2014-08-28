require 'optparse'
require 'yaml'
require 'fileutils'

module Delayed
class Pool

  attr_reader :options, :workers

  def initialize(args = ARGV)
    @args = args
    @workers = {}
    @config = { :workers => [] }
    @options = {
      :config_file => expand_rails_path("config/delayed_jobs.yml"),
      :pid_folder => expand_rails_path("tmp/pids"),
      :tail_logs => true, # only in FG mode
    }
  end

  def run
    if GC.respond_to?(:copy_on_write_friendly=)
      GC.copy_on_write_friendly = true
    end

    op = OptionParser.new do |opts|
      opts.banner = "Usage #{$0} <command> <options>"
      opts.separator %{\nWhere <command> is one of:
  start      start the jobs daemon
  stop       stop the jobs daemon
  run        start and run in the foreground
  restart    stop and then start the jobs daemon
  status     show daemon status
}

      opts.separator "\n<options>"
      opts.on("-c", "--config", "Use alternate config file (default #{options[:config_file]})") { |c| options[:config_file] = c }
      opts.on("-p", "--pid", "Use alternate folder for PID files (default #{options[:pid_folder]})") { |p| options[:pid_folder] = p }
      opts.on("--no-tail", "Don't tail the logs (only affects non-daemon mode)") { options[:tail_logs] = false }
      opts.on("--with-prejudice", "When stopping, interrupt jobs in progress, instead of letting them drain") { options[:kill] ||= true }
      opts.on("--with-extreme-prejudice", "When stopping, immediately kill jobs in progress, instead of letting them drain") { options[:kill] = 9 }
      opts.on_tail("-h", "--help", "Show this message") { puts opts; exit }
    end
    op.parse!(@args)

    read_config(options[:config_file])

    command = @args.shift
    case command
    when 'start'
      exit 1 if status(:alive) == :running
      daemonize
      start
    when 'stop'
      stop(options[:kill])
    when 'run'
      start
    when 'status'
      if status
        exit 0
      else
        exit 1
      end
    when 'restart'
      alive = status(false)
      if alive == :running || (options[:kill] && alive == :draining)
        stop(options[:kill])
        if options[:kill]
          sleep(0.5) while status(false)
        else
          sleep(0.5) while status(false) == :running
        end
      end
      daemonize
      start
    when nil
      puts op
    else
      raise("Unknown command: #{command.inspect}")
    end
  end

  protected

  def procname
    name = "delayed_jobs_pool"
    if Canvas.revision
      name = "#{name} (#{Canvas.revision})"
    end
    name
  end

  def start
    load_rails
    tail_rails_log unless @daemon

    say "Started job master", :info
    $0 = procname
    apply_config

    # fork to handle unlocking (to prevent polluting the parent with worker objects)
    unlock_pid = fork_with_reconnects do
      unlock_orphaned_jobs
    end
    Process.wait unlock_pid

    spawn_periodic_auditor
    spawn_all_workers
    say "Workers spawned"
    join
    say "Shutting down"
  rescue Interrupt => e
    say "Signal received, exiting", :info
  rescue Exception => e
    say "Job master died with error: #{e.inspect}\n#{e.backtrace.join("\n")}", :fatal
    raise
  end

  def say(msg, level = :debug)
    if defined?(Rails.logger) && Rails.logger
      Rails.logger.send(level, "[#{Process.pid}]P #{msg}")
    else
      puts(msg)
    end
  end

  def load_rails
    require(expand_rails_path("config/environment.rb"))
    Dir.chdir(Rails.root)
  end

  def unlock_orphaned_jobs(worker = nil, pid = nil)
    # don't bother trying to unlock jobs by process name if the name is overridden
    return if @config.key?(:name)
    return if @config[:disable_automatic_orphan_unlocking]
    return if @config[:workers].any? { |worker_config| worker_config.key?(:name) || worker_config.key?('name') }

    unlocked_jobs = Delayed::Job.unlock_orphaned_jobs(pid)
    say "Unlocked #{unlocked_jobs} orphaned jobs" if unlocked_jobs > 0
    ActiveRecord::Base.connection_handler.clear_all_connections! unless Rails.env.test?
  end

  def spawn_all_workers
    ActiveRecord::Base.connection_handler.clear_all_connections!

    @config[:workers].each do |worker_config|
      worker_config = worker_config.with_indifferent_access
      (worker_config[:workers] || 1).times { spawn_worker(@config.merge(worker_config)) }
    end
  end

  def spawn_worker(worker_config)
    if worker_config[:periodic]
      return # backwards compat
    else
      queue = worker_config[:queue] || Delayed::Worker.queue
      worker_config[:parent_pid] = Process.pid
      worker = Delayed::Worker.new(worker_config)
    end

    pid = fork_with_reconnects do
      Delayed::Periodic.load_periodic_jobs_config
      worker.start
    end
    workers[pid] = worker
  end

  # child processes need to reconnect so they don't accidentally share redis or
  # db connections with the parent
  def fork_with_reconnects
    fork do
      Canvas.reconnect_redis
      Delayed::Job.reconnect!
      yield
    end
  end

  def spawn_periodic_auditor
    return if @config[:disable_periodic_jobs]

    # audit any periodic job overrides for invalid cron lines
    # we do this here to fail as early as possible
    Delayed::Periodic.audit_overrides!

    @periodic_thread = Thread.new do
      # schedule the initial audit immediately on startup
      schedule_periodic_audit
      # initial sleep is randomized, for some staggering in the audit calls
      # since job processors are usually all restarted at the same time
      sleep(rand(15 * 60))
      loop do
        schedule_periodic_audit
        sleep(15 * 60)
      end
    end
  end

  def schedule_periodic_audit
    pid = fork_with_reconnects do
      # we want to avoid db connections in the main pool process
      $0 = "delayed_periodic_audit_scheduler"
      Delayed::Periodic.load_periodic_jobs_config
      Delayed::Periodic.audit_queue
    end
    workers[pid] = :periodic_audit
  end

  def join
    loop do
      child = Process.wait
      if child
        worker = workers.delete(child)
        if worker.is_a?(Symbol)
          say "ran auditor: #{worker}"
        else
          say "child exited: #{child}, restarting", :info
          # fork to handle unlocking (to prevent polluting the parent with worker objects)
          unlock_pid = fork_with_reconnects do
            unlock_orphaned_jobs(worker, child)
          end
          Process.wait unlock_pid
          spawn_worker(worker.config)
        end
      end
    end
  end

  def tail_rails_log
    return if !@options[:tail_logs]
    return if !Rails.logger.respond_to?(:log_path)
    Rails.logger.auto_flushing = true if Rails.logger.respond_to?(:auto_flushing=)
    Thread.new do
      f = File.open(Rails.logger.log_path, 'r')
      f.seek(0, IO::SEEK_END)
      loop do
        content = f.read
        content.present? ? STDOUT.print(content) : sleep(0.5)
      end
    end
  end

  def daemonize
    FileUtils.mkdir_p(pid_folder)
    puts "Daemonizing..."

    exit if fork
    Process.setsid
    exit if fork
    Process.setpgrp

    @daemon = true
    File.open(pid_file, 'wb') { |f| f.write(Process.pid.to_s) }
    # if we blow up so badly that we can't syslog the error, try to send
    # it somewhere useful
    last_ditch_logfile = self.last_ditch_logfile || "log/delayed_job.log"
    if last_ditch_logfile[0] != '|'
      last_ditch_logfile = expand_rails_path(last_ditch_logfile)
    end
    STDIN.reopen("/dev/null")
    STDOUT.reopen(open(last_ditch_logfile, 'a'))
    STDERR.reopen(STDOUT)
    STDOUT.sync = STDERR.sync = true
  end

  def pid_folder
    options[:pid_folder]
  end

  def pid_file
    File.join(pid_folder, 'delayed_jobs_pool.pid')
  end

  def remove_pid_file
    return unless @daemon
    pid = File.read(pid_file) if File.file?(pid_file)
    if pid.to_i == Process.pid
      FileUtils.rm(pid_file)
    end
  end

  def last_ditch_logfile
    @config['last_ditch_logfile']
  end

  def stop(kill = false)
    pid = status(false) && File.read(pid_file).to_i if File.file?(pid_file)
    if pid && pid > 0
      puts "Stopping pool #{pid}..."
      signal = 'INT'
      if kill
        pid = -pid # send to the whole group
        if kill == 9
          signal = 'KILL'
        else
          signal = 'TERM'
        end
      end
      begin
        Process.kill(signal, pid)
      rescue Errno::ESRCH
        # ignore if the pid no longer exists
      end
    else
      status
    end
  end

  def status(print = true)
    pid = File.read(pid_file) if File.file?(pid_file)
    alive = pid && pid.to_i > 0 && (Process.kill(0, pid.to_i) rescue false) && :running
    alive ||= :draining if pid.to_i > 0 && Process.kill(0, -pid.to_i) rescue false
    if alive
      puts "Delayed jobs #{alive}, pool PID: #{pid}" if print
    else
      puts "No delayed jobs pool running" if print && print != :alive
    end
    alive
  end

  def read_config(config_filename)
    config = YAML.load_file(config_filename)
    env = defined?(RAILS_ENV) ? RAILS_ENV : ENV['RAILS_ENV'] || 'development'
    @config = config[env] || config['default']
    # Backwards compatibility from when the config was just an array of queues
    @config = { :workers => @config } if @config.is_a?(Array)
    unless @config && @config.is_a?(Hash)
      raise ArgumentError,
        "Invalid config file #{config_filename}"
    end
  end

  def apply_config
    @config = @config.with_indifferent_access
    Worker::Settings.each do |setting|
      Worker.send("#{setting}=", @config[setting.to_s]) if @config.key?(setting.to_s)
    end
  end

  def expand_rails_path(path)
    File.expand_path("../../../../../../#{path}", __FILE__)
  end

end
end
