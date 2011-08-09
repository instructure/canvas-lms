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
end
