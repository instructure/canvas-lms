#
# Copyright (C) 2013 - present Instructure, Inc.
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

class AuthenticationProvider::Delegated < AuthenticationProvider
  after_create :disable_open_registration

  def disable_open_registration
    if self.account.open_registration?
      self.account.settings[:open_registration] = false
      self.account.save!
    end
  end

  def user_logout_redirect(controller, _current_user)
    # can we send them to a disambiguation page?
    return account.auth_discovery_url if account.auth_discovery_url
    # Canvas or LDAP primary provider; go to the login url cause it won't
    # auto-log them back in
    primary_auth = account.authentication_providers.active.first
    if primary_auth.is_a?(AuthenticationProvider::Canvas) ||
      primary_auth.is_a?(AuthenticationProvider::LDAP)
      return controller.login_url
    end
    # otherwise, just go to a landing page
    controller.logout_url
  end
end
