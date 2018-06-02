#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AddSamlRequestedAuthnContext < ActiveRecord::Migration[4.2]
  tag :predeploy

  class AuthenticationProvider < ActiveRecord::Base
    self.table_name = 'account_authorization_configs'
  end

  def self.up
    add_column :account_authorization_configs, :requested_authn_context, :string

    AuthenticationProvider.where(auth_type: "saml").each do |aac|
      # This was the hard-coded value before
      aac.requested_authn_context = Onelogin::Saml::AuthnContexts::PASSWORD_PROTECTED_TRANSPORT
      aac.save!
    end
    AuthenticationProvider.reset_column_information
  end

  def self.down
    remove_column :account_authorization_configs, :requested_authn_context
  end
end
