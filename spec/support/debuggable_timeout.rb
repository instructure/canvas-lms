# disable timeouts (in particular the spec one) once we start a pry session
#
# note: there's not really a great way to detect when the session is done,
# and making this only disable the spec timeout would be a lot more code.
# so once you start up pry, all timeouts are disabled, but ¯\_(ツ)_/¯

Timeout.singleton_class.prepend(Module.new {
  def sleep(*)
    result = super
    in_debugger_land = defined?(Pry) && Pry::InputLock.input_locks.any?

    if in_debugger_land
      # abort the timeout thread, otherwise it will raise in the main
      # thread once sleep returns
      Thread.current.kill
    end

    result
  end
})
