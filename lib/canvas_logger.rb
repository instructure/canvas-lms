require 'active_support'

class CanvasLogger < ActiveSupport::Logger
  CAPTURE_LIMIT = 10_000

  attr_reader :log_path, :captured_messages

  def initialize(log_path, level = DEBUG, options = {})
    unless File.exist?(log_path)
      FileUtils.mkdir_p(File.dirname(log_path))
    end
    super(log_path, level)
    @logdev = GroupWritableLogDevice.new(log_path)
    @log_path = log_path
    @skip_thread_context = options[:skip_thread_context]
  end

  def add(severity, message=nil, progname=nil, &block)
    return if level > severity
    message = (message || (block && block.call) || progname).to_s
    # If a newline is necessary then create a new message ending with a newline.
    # Ensures that the original message is not mutated.
    unless @skip_thread_context
      context = Thread.current[:context] || {}
      message = "[#{context[:session_id] || "-"} #{context[:request_id] || "-"}] #{message}"
    end

    if @captured_messages && @captured_messages.length < CAPTURE_LIMIT
      @captured_messages << "[#{Time.now.to_s}] #{message}"
    end

    super(severity, message, progname)
  end

  def reopen(log_path)
    unless File.exist?(log_path)
      FileUtils.mkdir_p(File.dirname(log_path))
    end
    @log_path = log_path

    old_logdev = @logdev
    @logdev = ::Logger::LogDevice.new(log_path, :shift_age => 0, :shift_size => 1048576)
    old_logdev.close
  end

  def capture_messages
    @captured_messages = []
    begin
      yield
    ensure
      @captured_messages = nil
    end
  end

  # On production we're running the server as a particular user, but we have the log
  # file permissions to be group writable. This is because Capistrano deploys run
  # as a different user and have to write to the logs while running rake tasks.
  # This LogDevice overrides the default permissions on file create from 644 to 664.
  # 
  # Note: when the Rails.logger rotates the log b/c it hits the shift_size (instead of waiting for
  # logrotate to run on the machine) it fubar's the permissions b/c it just let's the kernel do it's
  # thing based on umask. It feels risky to muck with the umask, so this is a safer hack to keep
  # the thing group writable.
  class GroupWritableLogDevice < Logger::LogDevice
    def create_logfile(filename)
      super.tap {|f| f.chmod(0664) }
    end
  end

end
