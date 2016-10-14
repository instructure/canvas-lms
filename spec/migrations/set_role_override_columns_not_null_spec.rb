#
# Copyright (C) 2015 Instructure, Inc.
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

require_relative '../spec_helper.rb'
require 'db/migrate/20160122192633_set_role_override_columns_not_null'

describe 'SetRoleOverrideColumnsNotNull' do
  before do
    SetRoleOverrideColumnsNotNull.down
  end

  after do
    RoleOverride.reset_column_information
  end

  describe "up" do
    it "preserves an RO intended to lock and inherit" do
      role = Role.built_in_account_roles.first
      ro = Account.default.role_overrides.create!(permission: 'post_to_forum', role: role, enabled: false, locked: true)
      RoleOverride.where(id: ro).update_all(enabled: nil)
      ro.reload
      expect(ro.enabled).to eq nil

      SetRoleOverrideColumnsNotNull.up
      ro.reload
      expect(ro.enabled).to eq true
    end

    it "preserves an RO intended to lock and inherit (disabled)" do
      role = Role.built_in_account_roles.first
      Account.default.role_overrides.create!(permission: 'post_to_forum', role: role, enabled: false, locked: false)
      sub_account = Account.default.sub_accounts.create!
      ro = sub_account.role_overrides.create!(permission: 'post_to_forum', role: role, enabled: false, locked: true)
      RoleOverride.where(id: ro).update_all(enabled: nil)
      ro.reload
      expect(ro.enabled).to eq nil

      SetRoleOverrideColumnsNotNull.up
      ro.reload
      expect(ro.enabled).to eq false
    end
  end
end
