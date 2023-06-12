# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe "DataFixup::AddRoleOverridesForNewPermission" do
  it "makes new role overrides" do
    RoleOverride.create!(context: Account.default,
                         permission: "read_forum",
                         role: teacher_role,
                         enabled: false)
    RoleOverride.create!(context: Account.default,
                         permission: "moderate_forum",
                         role: admin_role,
                         enabled: true)
    DataFixup::AddRoleOverridesForNewPermission.run(:moderate_forum, :read_forum)
    new_ro = RoleOverride.where(permission: "read_forum", role_id: admin_role.id).first
    expect(new_ro.context).to eq Account.default
    expect(new_ro.role).to eq admin_role
    expect(new_ro.enabled).to be_truthy
    old_ro = RoleOverride.where(permission: "read_forum", role_id: teacher_role.id).first
    expect(old_ro.enabled).to be_falsey
  end
end
