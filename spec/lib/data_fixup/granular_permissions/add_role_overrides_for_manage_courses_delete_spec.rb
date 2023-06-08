# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe "DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete" do
  def create_role_override(permission, role, enabled: false)
    RoleOverride.create!(
      context: @account,
      permission: permission.to_s,
      role:,
      enabled:
    )
  end

  before(:once) do
    @account = account_model(parent_account: Account.default)
    @account_membership_role =
      @account.roles.create(name: "Custom Account Role", base_role_type: "AccountMembership")
    @account_membership_role2 =
      @account.roles.create(name: "Custom Account Role2", base_role_type: "AccountMembership")
    @account_admin_role =
      @account.roles.create(name: "Custom Admin Role", base_role_type: "AccountAdmin")
    @account_admin_role2 =
      @account.roles.create(name: "Custom Admin Role2", base_role_type: "AccountAdmin")
  end

  it "is idempotent" do
    create_role_override("manage_courses", @account_admin_role, enabled: false)

    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
      base_role_type: "AccountAdmin"
    )

    expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 1

    expect do
      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountAdmin"
      )
    end.to_not raise_error
  end

  context "AccountAdmin" do
    it "creates a role override that is not enabled if either base role override is not enabled" do
      create_role_override("manage_courses", @account_admin_role, enabled: true)
      create_role_override("change_course_state", @account_admin_role, enabled: false)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountAdmin"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 1
      new_ro =
        RoleOverride.where(permission: "manage_courses_delete", role_id: @account_admin_role.id)
                    .first
      expect(new_ro.context).to eq @account
      expect(new_ro.role).to eq @account_admin_role
      expect(new_ro.enabled).to be_falsey
      old_manage_courses_ro =
        RoleOverride.where(permission: "manage_courses", role_id: @account_admin_role.id).first
      old_change_course_state_ro =
        RoleOverride.where(permission: "change_course_state", role_id: @account_admin_role.id).first
      expect(old_manage_courses_ro.enabled).to be_truthy
      expect(old_change_course_state_ro.enabled).to be_falsey
    end

    it "creates a new role override for :manage_courses_delete that is disabled" do
      create_role_override("manage_courses", @account_admin_role, enabled: false)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountAdmin"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 1
      new_ro =
        RoleOverride.where(permission: "manage_courses_delete", role_id: @account_admin_role.id)
                    .first
      expect(new_ro.context).to eq @account
      expect(new_ro.role).to eq @account_admin_role
      expect(new_ro.enabled).to be_falsey
      old_manage_courses_ro =
        RoleOverride.where(permission: "manage_courses", role_id: @account_admin_role.id).first
      expect(old_manage_courses_ro.enabled).to be_falsey
    end

    it "does not create a role override if both base role overrides are enabled" do
      create_role_override("manage_courses", @account_admin_role, enabled: true)
      create_role_override("change_course_state", @account_admin_role, enabled: true)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountAdmin"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 0
    end

    it "only creates one new role override per base role override type" do
      create_role_override("manage_courses", @account_admin_role, enabled: false)
      create_role_override("change_course_state", @account_admin_role, enabled: false)
      create_role_override("manage_courses", @account_admin_role2, enabled: false)
      create_role_override("change_course_state", @account_admin_role2, enabled: false)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountAdmin"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 2
    end

    it "does not create a new role override if no base role overrides exist" do
      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountAdmin"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 0
      expect(RoleOverride.where(permission: "manage_courses").count).to eq 0
      expect(RoleOverride.where(permission: "change_course_state").count).to eq 0
    end
  end

  context "AccountMembership" do
    it "only creates a role override if both base role overrides are enabled" do
      create_role_override("manage_courses", @account_membership_role, enabled: true)
      create_role_override("change_course_state", @account_membership_role, enabled: true)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountMembership"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 1
      new_ro =
        RoleOverride.where(
          permission: "manage_courses_delete",
          role_id: @account_membership_role.id
        ).first
      expect(new_ro.context).to eq @account
      expect(new_ro.role).to eq @account_membership_role
      expect(new_ro.enabled).to be_truthy
      old_manage_courses_ro =
        RoleOverride.where(permission: "manage_courses", role_id: @account_membership_role.id).first
      old_change_course_state_ro =
        RoleOverride.where(permission: "change_course_state", role_id: @account_membership_role.id)
                    .first
      expect(old_manage_courses_ro.enabled).to be_truthy
      expect(old_change_course_state_ro.enabled).to be_truthy
    end

    it "does not create a role override if either base role override is disabled" do
      create_role_override("manage_courses", @account_membership_role, enabled: true)
      create_role_override("change_course_state", @account_membership_role, enabled: false)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountMembership"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 0
    end

    it "does not create a new role override if no base role overrides exist" do
      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountMembership"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 0
      expect(RoleOverride.where(permission: "manage_courses").count).to eq 0
      expect(RoleOverride.where(permission: "change_course_state").count).to eq 0
    end

    it "only creates one new role override per base role override type" do
      create_role_override("manage_courses", @account_membership_role, enabled: true)
      create_role_override("change_course_state", @account_membership_role, enabled: true)
      create_role_override("manage_courses", @account_membership_role2, enabled: true)
      create_role_override("change_course_state", @account_membership_role2, enabled: true)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesDelete.run(
        base_role_type: "AccountMembership"
      )

      expect(RoleOverride.where(permission: "manage_courses_delete").count).to eq 2
    end
  end
end
