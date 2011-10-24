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
    if !Canvas::Security.allow_login_attempt?(attempted_record, remote_ip)
      self.too_many_attempts = true
      errors.add(password_field, I18n.t('errors.max_attempts', 'Too many failed login attempts. Please try again later or contact your system administrator.'))
      return
    end

    if invalid_password?
      Canvas::Security.failed_login!(attempted_record, remote_ip)
    else
      Canvas::Security.successful_login!(attempted_record, remote_ip)
    end
  end

  def too_many_attempts?
    too_many_attempts == true
  end
end
