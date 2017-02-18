module CallStackUtils
  def self.best_line_for(call_stack, except = nil)
    root = Rails.root.to_s + "/"
    lines = call_stack
    lines = lines.reject { |l| l =~ except } if except
    app_lines = lines.select { |s| s.starts_with?(root) }
    line = app_lines.grep(%r{_spec\.rb:}).first ||
           app_lines.grep(%r{/spec(_canvas?)/}).first ||
           app_lines.first ||
           lines.first
    line.sub(root, '')
  end

  # when raising in a utility function, get a useful backtrace
  # for the exception so that the rspec error context is obvious
  #
  # basically discard everything within the method where useful_backtrace
  # is called (or target_method, if provided)
  def self.useful_backtrace(target_method = nil)
    bt = caller

    # are we in a block in the method?
    if target_method.nil? && bt.first =~ /in `block.*? in ([a-z0-9_]+)'/
      target_method = $1
    end

    # throw away everything up to the method call
    bt.shift while target_method && bt.first !~ /in `#{Regexp.escape(target_method)}'/

    # now thow it away
    bt.shift

    bt
  end

  # (re-)raise the exception while preserving its backtrace
  def self.raise(exception)
    super exception.class, exception.message, exception.backtrace
  end
end
