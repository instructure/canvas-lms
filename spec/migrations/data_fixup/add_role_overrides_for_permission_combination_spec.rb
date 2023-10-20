# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

describe "DataFixup::AddRoleOverridesForPermissionCombination" do
  it "does nothing if no overrides for the old_permissions exist" do
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades read_roster],
      new_permission: :view_admin_analytics
    )
    expect(RoleOverride.where(permission: :view_admin_analytics)).not_to exist
  end

  it "creates an enabled role override for roles with overrides for all old_permissions" do
    Account.default.role_overrides.create!(permission: :view_all_grades, role: admin_role, enabled: true)
    Account.default.role_overrides.create!(permission: :read_roster, role: admin_role, enabled: true)
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades read_roster],
      new_permission: :view_admin_analytics
    )
    new_ro = Account.default.role_overrides.where(permission: :view_admin_analytics, role_id: admin_role).take
    expect(new_ro.enabled).to be true
  end

  it "creates an enabled role override for roles with a mix of enabled overrides/implicitly allowed old_permissions" do
    Account.default.role_overrides.create!(permission: :view_all_grades, role: admin_role, enabled: true)
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades read_roster],
      new_permission: :view_admin_analytics
    )
    new_ro = Account.default.role_overrides.where(permission: :view_admin_analytics, role_id: admin_role).take
    expect(new_ro.enabled).to be true
  end

  it "creates a disabled role override for roles with any of old_permissions disabled" do
    Account.default.role_overrides.create!(permission: :view_all_grades, role: admin_role, enabled: false)
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades read_roster],
      new_permission: :view_admin_analytics
    )
    new_ro = Account.default.role_overrides.where(permission: :view_admin_analytics, role_id: admin_role).take
    expect(new_ro.enabled).to be false
  end

  it "does not create a role override when an old permission is implicitly disabled" do
    Account.default.role_overrides.create!(permission: :read_roster, role: teacher_role, enabled: true)
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[read_roster view_audit_trail],
      new_permission: :view_admin_analytics
    )
    expect(Account.default.role_overrides.where(permission: :view_admin_analytics)).not_to exist
  end

  it "limits roles by base_role_type" do
    test_role = custom_account_role("test", account: Account.default)
    Account.default.role_overrides.create!(permission: :view_all_grades, role: test_role, enabled: true)
    Account.default.role_overrides.create!(permission: :view_all_grades, role: teacher_role, enabled: true)
    Account.default.role_overrides.create!(permission: :view_all_grades, role: ta_role, enabled: true)

    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades],
      new_permission: :view_admin_analytics,
      base_role_types: %i[TeacherEnrollment AccountMembership]
    )
    expect(Account.default.role_overrides.where(role: test_role, permission: :view_admin_analytics)).to exist
    expect(Account.default.role_overrides.where(role: teacher_role, permission: :view_admin_analytics)).to exist
    expect(Account.default.role_overrides.where(role: ta_role, permission: :view_admin_analytics)).not_to exist
  end

  it "does not create role overrides where they already exist" do
    Account.default.role_overrides.create!(permission: :view_all_grades, role: admin_role, enabled: true)
    Account.default.role_overrides.create!(permission: :read_roster, role: admin_role, enabled: true)
    new_old_ro = Account.default.role_overrides.create!(permission: :view_admin_analytics, role: admin_role, enabled: false)
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades read_roster],
      new_permission: :view_admin_analytics
    )
    expect(new_old_ro.reload.enabled).to be false
  end

  it "combines the applies_to_* fields from old_permissions" do
    Account.default.role_overrides.create!(permission: :view_all_grades, role: admin_role, enabled: true, applies_to_self: false, applies_to_descendants: true)
    Account.default.role_overrides.create!(permission: :read_roster, role: admin_role, enabled: true, applies_to_self: true, applies_to_descendants: true)
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades read_roster],
      new_permission: :view_admin_analytics
    )
    new_ro = Account.default.role_overrides.where(permission: :view_admin_analytics, role_id: admin_role).take
    expect(new_ro.enabled).to be true
    expect(new_ro.applies_to_self).to be false
    expect(new_ro.applies_to_descendants).to be true
  end

  it "combines the locked fields from old_permissions" do
    Account.default.role_overrides.create!(permission: :view_all_grades, role: admin_role, enabled: true, locked: false)
    Account.default.role_overrides.create!(permission: :read_roster, role: admin_role, enabled: true, locked: false)
    Account.default.role_overrides.create!(permission: :view_all_grades, role: teacher_role, enabled: false, locked: true)
    Account.default.role_overrides.create!(permission: :read_roster, role: teacher_role, enabled: true, locked: false)
    DataFixup::AddRoleOverridesForPermissionCombination.run(
      old_permissions: %i[view_all_grades read_roster],
      new_permission: :view_admin_analytics
    )
    admin_ro = Account.default.role_overrides.where(permission: :view_admin_analytics, role_id: admin_role).take
    expect(admin_ro.enabled).to be true
    expect(admin_ro.locked).to be false
    teacher_ro = Account.default.role_overrides.where(permission: :view_admin_analytics, role_id: teacher_role).take
    expect(teacher_ro.enabled).to be false
    expect(teacher_ro.locked).to be true
  end
end
