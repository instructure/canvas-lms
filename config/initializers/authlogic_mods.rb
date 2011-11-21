module Authlogic
  module ControllerAdapters
    class RailsAdapter < AbstractAdapter
      # this helper for rails redefines this method to do the wrong thing.
      # we remove here so that we get the original method.
      remove_method :authenticate_with_http_basic
    end
  end
end

# we need http basic auth to take precedence over the session cookie, for the api.
cb = Authlogic::Session::Base.persist_callback_chain.delete(:persist_by_http_auth)
Authlogic::Session::Base.persist_callback_chain.unshift(cb) if cb
# we also need the session cookie to take precendence over the "remember me" cookie,
# otherwise we'll use the "remember me" cookie every request, which triggers
# generating a new "remember me" cookie since they're one-time use.
cb = Authlogic::Session::Base.persist_callback_chain.delete(:persist_by_cookie)
Authlogic::Session::Base.persist_callback_chain.push(cb) if cb
