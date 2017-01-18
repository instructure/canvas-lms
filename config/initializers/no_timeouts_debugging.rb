if Rails.env.development? || Rails.env.test?

  # this prevents timeouts from occurring when you're debugging a process
  # It hooks into the specific raise used by Timeout, and if byebug has
  # been started (i.e. we have ever broken into the debugger), it ignores
  # the exception. otherwise, it's business as usual
  # This is useful so that you can debug specs (which are run in a timeout
  # block), or simply debug anything in canvas that has timeouts
  module NoRaiseTimeoutsWhileDebugging
    def raise(*args)
      if args.first.is_a?(Timeout::Error) && defined?(Byebug) && Byebug.respond_to?(:started?) && Byebug.started?
        return
      end
      super
    end
  end

  Thread.prepend(NoRaiseTimeoutsWhileDebugging)
end
