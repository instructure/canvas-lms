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

  # This LogDevice overrides the default permissions to be group writable when the logs 
  # are rotated and the new file is created.  By default, this happens when the log size 
  # hits 1MB. The size is controlled by the shift_size parameter.
  #
  # Note: when the Rails.logger rotates the log it just let's the kernel do it's thing in
  # terms of permissions for rotated file. This messes up our Capistrano deploys up b/c
  # the deploy runs as a different user than the Apache server and the deploy has to write to
  # the log while running rake tasks. We handle this by having the log file group writeable by
  # a group that the Capistrano deploy user is in. This feels safer than mucking with umasks.
  # But don't forget to set the setgid bit on the log file directory! E.g. chmod g+s /log/file/dir
  class GroupWritableLogDevice < Logger::LogDevice
    def create_logfile(filename)
      super.tap {|f| f.chmod(0664) }
    end
  end

end
