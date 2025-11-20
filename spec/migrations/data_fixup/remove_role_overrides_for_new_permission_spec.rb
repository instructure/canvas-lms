# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

describe "DataFixup::RemoveRoleOverridesForNewPermission" do
  let(:base_permission) { :become_user }
  let(:remove_permissions) { [:new_quizzes_view_ip_address, :new_quizzes_multiple_session_detection] }
  let(:account) { Account.default }
  let(:role) { Role.create!(name: "TestRole", base_role_type: "TeacherEnrollment", account:) }
  let(:admin_role) { Role.create!(name: "AdminRole", base_role_type: "AccountAdmin", account:) }

  it "does nothing if base permission is not valid" do
    expect do
      DataFixup::RemoveRoleOverridesForNewPermission.run("invalid_permission", remove_permissions)
    end.to raise_error("invalid_permission is not a valid permission")
  end

  it "does nothing if new permisions are not valid" do
    expect do
      DataFixup::RemoveRoleOverridesForNewPermission.run(base_permission, ["invalid_permission"])
    end.to raise_error("invalid_permission is not a valid permission")
  end

  it "does nothing if no overrides exist for the old permissions" do
    RoleOverride.create!(permission: base_permission, role:, enabled: true, context: account)
    expect do
      DataFixup::RemoveRoleOverridesForNewPermission.run(base_permission, remove_permissions)
    end.not_to change { RoleOverride.count }
  end

  it "removes role overrides for specified permissions when base permission exists" do
    base_override = RoleOverride.create!(permission: base_permission, role:, enabled: true, context: account)
    remove_override1 = RoleOverride.create!(permission: remove_permissions[0], role:, enabled: true, context: account)
    remove_override2 = RoleOverride.create!(permission: remove_permissions[1], role:, enabled: true, context: account)
    other_override = RoleOverride.create!(permission: remove_permissions[0], role: admin_role, enabled: true, context: account)

    expect do
      DataFixup::RemoveRoleOverridesForNewPermission.run(base_permission, remove_permissions)
    end.to change { RoleOverride.count }.by(-2)

    expect(RoleOverride.exists?(remove_override1.id)).to be_falsey
    expect(RoleOverride.exists?(remove_override2.id)).to be_falsey
    expect(RoleOverride.exists?(base_override.id)).to be_truthy
    expect(RoleOverride.exists?(other_override.id)).to be_truthy
  end

  it "skips validation when skip_validation is true" do
    expect do
      DataFixup::RemoveRoleOverridesForNewPermission.run("invalid_base", ["invalid_remove"], skip_validation: true)
    end.not_to raise_error
  end

  it "handles multiple roles with the same base permission" do
    role2 = Role.create!(name: "TestRole2", base_role_type: "TeacherEnrollment", account:)
    base_override1 = RoleOverride.create!(permission: base_permission, role:, enabled: true, context: account)
    base_override2 = RoleOverride.create!(permission: base_permission, role: role2, enabled: true, context: account)
    remove_override1 = RoleOverride.create!(permission: remove_permissions[0], role:, enabled: true, context: account)
    remove_override2 = RoleOverride.create!(permission: remove_permissions[0], role: role2, enabled: true, context: account)

    expect do
      DataFixup::RemoveRoleOverridesForNewPermission.run(base_permission, [remove_permissions[0]])
    end.to change { RoleOverride.count }.by(-2)

    expect(RoleOverride.exists?(remove_override1.id)).to be_falsey
    expect(RoleOverride.exists?(remove_override2.id)).to be_falsey
    expect(RoleOverride.exists?(base_override1.id)).to be_truthy
    expect(RoleOverride.exists?(base_override2.id)).to be_truthy
  end

  it "does not remove role overrides for skip_role_type" do
    test_role_become_user = RoleOverride.create!(permission: base_permission, role:, enabled: true, context: account)
    test_role_view_ip = RoleOverride.create!(permission: remove_permissions[0], role:, enabled: true, context: account)
    test_role_multi_sess = RoleOverride.create!(permission: remove_permissions[1], role:, enabled: true, context: account)

    admin_role_become_user = RoleOverride.create!(permission: base_permission, role: admin_role, enabled: true, context: account)
    admin_role_view_ip = RoleOverride.create!(permission: remove_permissions[0], role: admin_role, enabled: true, context: account)
    admin_role_multi_sess = RoleOverride.create!(permission: remove_permissions[1], role: admin_role, enabled: true, context: account)

    expect do
      DataFixup::RemoveRoleOverridesForNewPermission.run(base_permission, remove_permissions, skip_role_type: "AccountAdmin")
    end.to change { RoleOverride.count }.by(-2)

    expect(RoleOverride.exists?(test_role_become_user.id)).to be_truthy
    expect(RoleOverride.exists?(test_role_view_ip.id)).to be_falsey
    expect(RoleOverride.exists?(test_role_multi_sess.id)).to be_falsey

    expect(RoleOverride.exists?(admin_role_become_user.id)).to be_truthy
    expect(RoleOverride.exists?(admin_role_view_ip.id)).to be_truthy
    expect(RoleOverride.exists?(admin_role_multi_sess.id)).to be_truthy
  end
end
