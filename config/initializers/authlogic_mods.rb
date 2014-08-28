module Authlogic
  module ControllerAdapters
    class RailsAdapter < AbstractAdapter
      # this helper for rails redefines this method to do the wrong thing.
      # we remove here so that we get the original method.
      remove_method :authenticate_with_http_basic
    end
  end
end

callback_chain = Authlogic::Session::Base._persist_callbacks

# we need http basic auth to take precedence over the session cookie, for the api.
cb = callback_chain.delete(callback_chain.find { |cb| cb.filter == :persist_by_http_auth })
callback_chain.unshift(cb) if cb
# we also need the session cookie to take precendence over the "remember me" cookie,
# otherwise we'll use the "remember me" cookie every request, which triggers
# generating a new "remember me" cookie since they're one-time use.
cb = callback_chain.delete(callback_chain.find { |cb| cb.filter == :persist_by_cookie })
callback_chain.push(cb) if cb

# be tolerant of using a slave
Authlogic::Session::Callbacks.module_eval do
  def save_record_with_ro_check(alternate_record = nil)
    begin
      save_record_without_ro_check(alternate_record)
    rescue ActiveRecord::StatementInvalid => error
      # "simulated" slave of a user with read-only access; probably the same error for Slony
      raise if !error.message.match(/PG(?:::)?Error: ERROR: +permission denied for relation/) &&
          # real slave that's in recovery
          !error.message.match(/PG(?:::)?Error: ERROR: +cannot execute UPDATE in a read-only transaction/)
    end
  end
  alias_method_chain :save_record, :ro_check
end
