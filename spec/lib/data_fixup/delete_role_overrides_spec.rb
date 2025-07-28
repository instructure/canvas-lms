# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::DeleteRoleOverrides do
  before(:once) do
    @account1 = Account.create
    @account2 = Account.create

    @role1 = Role.find_by(root_account: @account1, name: "AccountAdmin")
    @role2 = Role.find_by(root_account: @account1, name: "StudentEnrollment")
    @role3 = Role.find_by(root_account: @account2, name: "AccountAdmin")

    @role_override1 = RoleOverride.create(account: @account1, role: @role1, permission: "apple")
    @role_override2 = RoleOverride.create(account: @account1, role: @role2, permission: "apple")
    @role_override3 = RoleOverride.create(account: @account1, role: @role1, permission: "pear")
    @role_override4 = RoleOverride.create(account: @account2, role: @role3, permission: "pear")
  end

  describe ".run" do
    it "deletes selected role overrides on all roles" do
      expect { DataFixup::DeleteRoleOverrides.run("apple") }.to change { RoleOverride.all }
        .from([@role_override1, @role_override2, @role_override3, @role_override4])
        .to([@role_override3, @role_override4])
    end

    it "deletes selected role overrides in all accounts" do
      expect { DataFixup::DeleteRoleOverrides.run("pear") }.to change { RoleOverride.all }
        .from([@role_override1, @role_override2, @role_override3, @role_override4])
        .to([@role_override1, @role_override2])
    end

    it "works with multiple arguments" do
      expect { DataFixup::DeleteRoleOverrides.run("apple", "pear") }.to change { RoleOverride.all }
        .from([@role_override1, @role_override2, @role_override3, @role_override4])
        .to([])
    end
  end
end
