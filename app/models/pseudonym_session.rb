#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class PseudonymSession < Authlogic::Session::Base
  last_request_at_threshold  10.minutes
  verify_password_method :valid_arbitrary_credentials?
  login_field :unique_id
  find_by_login_method :custom_find_by_unique_id
  remember_me_for 2.weeks

  attr_accessor :remote_ip, :too_many_attempts

  # we need to know if the session came from http basic auth, so we override
  # authlogic's method here to add a flag that we can check
  def persist_by_http_auth
    controller.authenticate_with_http_basic do |login, password|
      if !login.blank? && !password.blank?
        send("#{login_field}=", login)
        send("#{password_field}=", password)
        @valid_basic_auth = valid?
        return @valid_basic_auth
      end
    end

    false
  end
  def used_basic_auth?
    @valid_basic_auth
  end

  unless CANVAS_RAILS2
    # In authlogic 3.2.0, it tries to parse the last part of the cookie (delimited by '::')
    # as a timestamp to verify whether the cookie is stale.
    # This conflicts with the uuid that we use instead in that place,
    # so skip that check for now, to keep behavior similar between Rails 2 and 3.
    def remember_me_expired?
      false
    end
  end

  if CANVAS_RAILS2
    # modifications to authlogic's cookie persistence (used for the "remember me" token)
    # see the SessionPersistenceToken class for details
    #
    # also, the version of authlogic canvas is on doesn't support httponly (or
    # secure-only) for the "remember me" cookie yet, so we add that support here.
    def save_cookie
      return unless remember_me?
      token = SessionPersistenceToken.generate(record)
      controller.cookies[cookie_key] = {
        :value => token.pseudonym_credentials,
        :expires => remember_me_until,
        :domain => controller.cookie_domain,
        :httponly => true,
        :secure => controller.request.session_options[:secure],
      }
    end
  else
    secure CanvasRails::Application.config.session_options[:secure]
    httponly true

    # modifications to authlogic's cookie persistence (used for the "remember me" token)
    # see the SessionPersistenceToken class for details
    def save_cookie
      return unless remember_me?
      token = SessionPersistenceToken.generate(record)
      controller.cookies[cookie_key] = {
        :value => token.pseudonym_credentials,
        :expires => remember_me_until,
        :domain => controller.cookie_domain,
        :httponly => httponly,
        :secure => secure,
      }
    end
  end

  def persist_by_cookie
    cookie = controller.cookies[cookie_key]
    if cookie
      token = SessionPersistenceToken.find_by_pseudonym_credentials(cookie)
      self.unauthorized_record = token.use! if token
      is_valid = self.valid?
      if is_valid
        # this token has been used -- destroy it, and generate a new one
        # remember_me is implicitly true when they login via the remember_me token
        controller.session[:used_remember_me_token] = true
        self.remember_me = true
        self.save!
      end
      is_valid
    else
      false
    end
  end

  # added behavior: destroy the server-side SessionPersistenceToken as well as the browser cookie
  def destroy_cookie
    cookie = controller.cookies.delete cookie_key, :domain => controller.cookie_domain
    return true unless cookie
    token = SessionPersistenceToken.find_by_pseudonym_credentials(cookie)
    token.try(:destroy)
    true
  end

  # Validate the session using password auth (either local or LDAP, but not
  # SSO). If too many failed attempts have occured, the validation will fail.
  # In this case, `too_many_attempts?` will be true, rather than
  # `invalid_password?`.
  #
  # Note that for IP based max attempt tracking to occur, you'll need to set
  # remote_ip on the PseudonymSession before calling save/valid?. Otherwise,
  # only total # of failed attempts will be tracked.
  def validate_by_password
    super

    # have to call super first, as that's what loads attempted_record
    if too_many_attempts? || attempted_record.try(:audit_login, remote_ip, !invalid_password?) == :too_many_attempts
      self.too_many_attempts = true
      errors.add(password_field, I18n.t('errors.max_attempts', 'Too many failed login attempts. Please try again later or contact your system administrator.'))
      return
    end
  end

  def too_many_attempts?
    too_many_attempts == true
  end
end
