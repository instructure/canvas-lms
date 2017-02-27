if Rails.env.development? || Rails.env.test?

  # This prevents timeouts from occurring once you've started debugging a
  # process. It hooks into the specific raise used by Timeout, and if we're
  # in a debugging mood (i.e. we have ever broken into the debugger), it
  # ignores the exception. Otherwise, it's business as usual.
  #
  # This is useful so that you can debug specs (which are run in a timeout
  # block), or simply debug anything in canvas that has timeouts
  #
  # Notes:
  #  * Byebug prevents the timeout thread from even running when you are
  #    inside the debugger (it resumes afterward), so basically we just
  #    have to disable timeouts altogether if you have ever debugger'd
  #  * In a similar vein, although the timeout thread does run while Pry
  #    is doing its thing, there's not an easy way to know when you are
  #    done Pry-ing, so we just turn it off there as well.
  #
  module NoRaiseTimeoutsWhileDebugging
    def raise(*args)
      if args.first.is_a?(Timeout::Error)
        have_ever_run_a_debugger = (
          defined?(Byebug) && Byebug.respond_to?(:started?) ||
          defined?(Pry) && Pry::InputLock.input_locks.any?
        )
        return if have_ever_run_a_debugger
      end
      super
    end
  end

  Thread.prepend(NoRaiseTimeoutsWhileDebugging)
end
