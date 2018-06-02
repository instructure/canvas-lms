#
# Copyright (C) 2018 - present Instructure, Inc.
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

class DisableNoTlsForLdap < ActiveRecord::Migration[5.0]
  tag :postdeploy

  class AuthenticationProvider < ActiveRecord::Base
    self.table_name = 'account_authorization_configs'

    def auth_over_tls
      ::AuthenticationProvider::LDAP.auth_over_tls_setting(read_attribute(:auth_over_tls))
    end
  end

  def up
    AuthenticationProvider.where(auth_type: 'ldap', workflow_state: 'active').each do |ap|
      ap.update_attribute(:auth_over_tls, 'start_tls') unless ap.auth_over_tls
    end
  end
end
