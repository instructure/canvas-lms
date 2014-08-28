require 'active_support'

class CanvasLogger < ActiveSupport::BufferedLogger
  attr_reader :log_path

  def initialize(log_path, level = DEBUG, options = {})
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
end
