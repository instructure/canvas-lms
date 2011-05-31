# authlogic doesn't support httponly (or secure-only) for the "remember me"
# cookie yet, so we get to monkey patch. there's an open pull request still
# pending:
# https://github.com/binarylogic/authlogic/issues/issue/210

module Authlogic::Session::Cookies::InstanceMethods
  def save_cookie
    controller.cookies[cookie_key] = {
      :value => "#{record.persistence_token}::#{record.send(record.class.primary_key)}",
      :expires => remember_me_until,
      :domain => controller.cookie_domain,
      :httponly => true,
      :secure => ActionController::Base.session_options[:secure],
    }
  end
end
