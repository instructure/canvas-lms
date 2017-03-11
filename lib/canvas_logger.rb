require 'active_support'

class CanvasLogger < ActiveSupport::Logger
  attr_reader :log_path

  def initialize(log_path, level = DEBUG, options = {})
    unless File.exist?(log_path)
      FileUtils.mkdir_p(File.dirname(log_path))
    end
    super(log_path, level)
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

  def capture_messages(&block)
    CanvasLogger.prepend Capture unless CanvasLogger.include?(Capture)
    capture_messages(&block)
  end

  def capture_messages!
    CanvasLogger.prepend Capture unless CanvasLogger.include?(Capture)
    captured_message_stack << []
  end

  module Capture
    CAPTURE_LIMIT = 10_000

    def captured_message_stack
      @captured_message_stack ||= []
    end

    def capture_messages!
      captured_messages.clear
    end

    def captured_messages
      captured_message_stack.last
    end

    def capture_messages
      captured_message_stack.push([])
      yield
      captured_messages
    ensure
      captured_message_stack.pop
      captured_messages
    end

    def add(severity, message=nil, progname=nil, &block)
      return if level > severity
      message = (message || (block && block.call) || progname).to_s
      captured_message = "[#{Time.now.to_s}] #{message}"
      captured_message_stack.each do |messages|
        messages << captured_message if messages.length < CAPTURE_LIMIT
      end
      super severity, message, progname
    end
  end
end
