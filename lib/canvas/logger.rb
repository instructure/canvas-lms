require 'active_support'

class CanvasLogger < ActiveSupport::BufferedLogger

  def initialize(log, level = DEBUG, options = {})
    super(log, level)
    @skip_thread_context = options[:skip_thread_context]
  end

  def add(severity, message=nil, progname=nil, &block)
    return if @level > severity
    message = (message || (block && block.call) || progname).to_s
    # If a newline is necessary then create a new message ending with a newline.
    # Ensures that the original message is not mutated.
    if @skip_thread_context
      message = "#{message}\n" unless message[-1] == ?\n
    else
      context = Thread.current[:context] || {}
      message = "[#{context[:session_id] || "-"} #{context[:request_id] || "-"}] #{message}#{"\n" unless message[-1] == ?\n}"
    end
    buffer << message
    auto_flush
    message
  end

end
