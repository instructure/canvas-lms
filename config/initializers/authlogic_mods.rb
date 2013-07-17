module Authlogic
  module ControllerAdapters
    class RailsAdapter < AbstractAdapter
      # this helper for rails redefines this method to do the wrong thing.
      # we remove here so that we get the original method.
      remove_method :authenticate_with_http_basic
    end
  end
end

callback_chain = Rails.version < "3.0" ? Authlogic::Session::Base.persist_callback_chain : Authlogic::Session::Base._persist_callbacks

# we need http basic auth to take precedence over the session cookie, for the api.
cb = callback_chain.delete(:persist_by_http_auth)
callback_chain.unshift(cb) if cb
# we also need the session cookie to take precendence over the "remember me" cookie,
# otherwise we'll use the "remember me" cookie every request, which triggers
# generating a new "remember me" cookie since they're one-time use.
cb = callback_chain.delete(:persist_by_cookie)
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

# i18n fix so the error gets translated at run time, not initialization time.
# this is fixed in new authlogic
# https://github.com/jovoto-team/authlogic/commit/db01cf108985bd176e1885a3c85450020d4bcc45
if Rails.version < '3.0'
  module Authlogic
    module ActsAsAuthentic
      module Login
        module Config
          def validates_format_of_login_field_options(value = nil)
            rw_config(:validates_format_of_login_field_options, value, {:with => Authlogic::Regex.login, :message => lambda {I18n.t('error_messages.login_invalid', "should use only letters, numbers, spaces, and .-_@ please.")}})
          end
          alias_method :validates_format_of_login_field_options=, :validates_format_of_login_field_options
        end
      end
    end
  end
end
