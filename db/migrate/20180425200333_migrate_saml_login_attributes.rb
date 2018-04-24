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
#

class MigrateSamlLoginAttributes < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def up
    AuthenticationProvider::SAML.where(login_attribute: 'nameid').update_all(login_attribute: 'NameID')
    AuthenticationProvider::SAML.where(login_attribute: 'eduPersonPrincipalName_stripped').each do |ap|
      ap.login_attribute = 'eduPersonPrincipalName'
      ap.strip_domain_from_login_attribute = true
      ap.save!
    end
  end

  def down
    AuthenticationProvider::SAML.where(login_attribute: 'NameID').update_all(login_attribute: 'nameid')
    AuthenticationProvider::SAML.where(login_attribute: 'eduPersonPrincipalName').each do |ap|
      next unless ap.strip_domain_from_login_attribute?
      ap.login_attribute = 'eduPersonPrincipalName_stripped'
      ap.save!
    end
  end
end
