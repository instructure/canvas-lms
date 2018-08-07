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

require 'sharding_spec_helper'

describe PermissionsHelper do
  describe '#manageable_enrollments_by_permission' do
    before :once do
      @student_role = Role.get_built_in_role('StudentEnrollment')
      @teacher_role = Role.get_built_in_role('TeacherEnrollment')
    end

    it 'should return enrollments that have permission by default' do
      course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([teacher_enrollment])
    end

    it 'should return enrollments that have permission from a direct account override' do
      student_enrollment = course_with_student(active_all: true)
      course_with_teacher(user: @user, active_all: true)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @student_role, account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment])
    end

    it 'should return enrollments that have permission from an ancestor account override' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      course_with_student(account: Account.default, active_all: true)
      student_enrollment2 = course_with_student(user: @user, account: sub_account2, active_all: true)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @student_role, account: sub_account1)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment2])
    end

    it 'should only return enrollments that have permission for the given override' do
      course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      RoleOverride.create!(permission: 'manage_grades', enabled: true, role: @student_role, account: Account.default)
      RoleOverride.create!(permission: 'manage_grades', enabled: false, role: @teacher_role, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([teacher_enrollment])
    end

    it 'should return enrollments that have permission from an account role' do
      student_enrollment = course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to eq([teacher_enrollment])
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: Account.default)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([student_enrollment, teacher_enrollment])
    end

    it 'should handle AccountAdmin roles' do
      student_enrollment = course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      admin_role = Role.get_built_in_role('AccountAdmin')
      @user.account_users.create!(account: Account.default, role: admin_role)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment, teacher_enrollment])
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: admin_role, account: Account.default)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([teacher_enrollment])
    end

    it 'should inherit AccountAdmin rights from a parent account' do
      subaccount = Account.default.sub_accounts.create!
      student_enrollment = course_with_student(active_all: true, account: subaccount)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true, account: subaccount)
      admin_role = Role.get_built_in_role('AccountAdmin')
      @user.account_users.create!(account: Account.default, role: admin_role)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment, teacher_enrollment])
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: admin_role, account: Account.default)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([teacher_enrollment])
    end

    it 'should use AccountAdmin permissions when another role disables the permission' do
      student_enrollment = course_with_student(active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: custom_role, account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role)
      @user.account_users.create!(account: Account.default, role: Role.get_built_in_role('AccountAdmin'))
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment])
    end

    it 'should handle account role overrides that conflict with course role overrides' do
      student_enrollment = course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to eq([])
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: Account.default)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([student_enrollment, teacher_enrollment])
    end

    it 'should handle account role overrides from a higher account that conflict with course role overrides' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      teacher_enrollment1 = course_with_teacher(account: root_account, active_all: true)
      teacher_enrollment2 = course_with_teacher(user: @user, account: sub_account2, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: sub_account2)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([teacher_enrollment1])
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: Account.default)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([teacher_enrollment1, teacher_enrollment2])
    end

    it 'should handle course role overrides from a higher account that conflict with account role overrides' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      course_with_teacher(active_all: true)
      teacher_enrollment2 = course_with_teacher(user: @user, account: sub_account2, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: sub_account2)
      @user.account_users.create!(account: sub_account2, role: custom_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([])
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: sub_account2)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([teacher_enrollment2])
    end

    it 'should handle role override disabling the permission in a lower account' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      course_with_student(active_all: true)
      student_enrollment2 = course_with_student(user: @user, account: sub_account2, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: sub_account1)
      @user.account_users.create!(account: sub_account2, role: custom_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: sub_account1)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment2])
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: custom_role, account: sub_account2)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([])
    end

    it 'should handle account role overrides from a lower account than the account the role belongs to' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      student_enrollment = course_with_student(user: @user, account: sub_account2, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: sub_account2)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment])
    end

    it 'should not be affected by role overrides in a sub-account of the current enrollment' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      course_with_student(user: @user, account: sub_account1, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: sub_account2)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([])
    end

    it 'should handle conflicting course enrollments' do
      teacher_enrollment = course_with_teacher(active_all: true)
      student_enrollment = course_with_student(user: @user, account: Account.default, course: @course, active_all: true)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to eq([teacher_enrollment])
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @student_role, account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: Account.default)
      enrollments2 = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments2).to match_array([student_enrollment])
    end

    it 'should handle role overrides that are turned on and off by sub-account' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      course_with_teacher(account: Account.default)
      teacher_enrollment_account1 = course_with_teacher(user: @user, account: sub_account1)
      course_with_teacher(user: @user, account: sub_account2)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @teacher_role, account: sub_account1)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: sub_account2)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([teacher_enrollment_account1])
    end

    it 'should handle locked overrides when there are sub-account overrides' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      course_with_teacher(account: Account.default)
      course_with_teacher(user: @user, account: sub_account1)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, locked: true, account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @teacher_role, account: sub_account1)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([])
    end

    it 'should handle role overrides that do not apply to self' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      course_with_teacher(account: Account.default)
      teacher_enrollment_account1 = course_with_teacher(user: @user, account: sub_account1)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @teacher_role,
        applies_to_self: false, applies_to_descendants: true, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([teacher_enrollment_account1])
    end

    it 'should handle role overrides that do not apply to descendants' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      student_enrollment_root = course_with_student(account: Account.default, active_all: true)
      course_with_student(user: @user, account: sub_account1, active_all: true)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @student_role,
        applies_to_self: true, applies_to_descendants: false, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment_root])
    end

    it 'should handle role overrides that do not apply to descendants and are locked' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      student_enrollment_root = course_with_student(account: root_account, active_all: true)
      course_with_student(user: @user, account: sub_account1, active_all: true)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @student_role,
        applies_to_self: true, applies_to_descendants: false, locked: true, account: root_account)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: @student_role,
        applies_to_self: true, applies_to_descendants: true, account: sub_account1)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment_root])
    end

    it 'should handle AccountAdmin when the permission is off by default' do
      student_enrollment = course_with_student(active_all: true)
      admin_role = Role.get_built_in_role('AccountAdmin')
      @user.account_users.create!(account: Account.default, role: admin_role)
      enrollments1 = @user.manageable_enrollments_by_permission(:view_notifications)
      expect(enrollments1).to match_array([])
      RoleOverride.create!(permission: 'view_notifications', enabled: true, role: admin_role, account: Account.default)
      enrollments2 = @user.manageable_enrollments_by_permission(:view_notifications)
      expect(enrollments2).to match_array([student_enrollment])
    end

    it 'should handle role overrides that turn off the permission for AccountAdmin but on for another account admin' do
      student_enrollment = course_with_student(active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      admin_role = Role.get_built_in_role('AccountAdmin')
      @user.account_users.create!(account: Account.default, role: custom_role)
      @user.account_users.create!(account: Account.default, role: admin_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: admin_role, account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment])
    end

    it 'should handle role overrides that turn off the permission for AccountAdmin and a course role that has it on by default' do
      teacher_enrollment = course_with_teacher(active_all: true)
      admin_role = Role.get_built_in_role('AccountAdmin')
      @user.account_users.create!(account: Account.default, role: admin_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: admin_role, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([teacher_enrollment])
    end

    it 'should handle AccountAdmin with the permission on when another override turns it off' do
      teacher_enrollment = course_with_teacher(active_all: true)
      admin_role = Role.get_built_in_role('AccountAdmin')
      @user.account_users.create!(account: Account.default, role: admin_role)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: @teacher_role, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([teacher_enrollment])
    end

    it 'should handle conflicting account role overrides' do
      student_enrollment = course_with_student(active_all: true)
      custom_role1 = custom_account_role('OverrideTest1', account: Account.default)
      custom_role2 = custom_account_role('OverrideTest2', account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role1)
      @user.account_users.create!(account: Account.default, role: custom_role2)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: custom_role1, account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role2, account: Account.default)
      enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
      expect(enrollments).to match_array([student_enrollment])
    end

    context "cross-sharding" do
      specs_require_sharding

      it "should handle cross-shard enrollment permissions" do
        @shard1.activate do
          @another_account = Account.create!
          course_with_student(active_all: true, account: @another_account)
          @teacher_enrollment1 = course_with_teacher(user: @user, active_all: true, account: @another_account)
        end
        course_with_student(user: @user, active_all: true)
        teacher_enrollment2 = course_with_teacher(user: @user, active_all: true)
        enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
        expect(enrollments).to match_array([teacher_enrollment2, @teacher_enrollment1])
      end

      it "should handle non-standard cross-shard enrollment permissions" do
        @shard1.activate do
          @another_account = Account.create!
          @student_enrollment1 = course_with_student(active_all: true, account: @another_account)
          @teacher_enrollment1 = course_with_teacher(user: @user, active_all: true, account: @another_account)
          @user.account_users.create!(account: @another_account, role: Role.get_built_in_role('AccountAdmin'))
          RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: Role.find_by(name: 'TeacherEnrollment'), account: @another_account)
        end
        student_enrollment2 = course_with_student(user: @user, active_all: true)
        teacher_enrollment2 = course_with_teacher(user: @user, active_all: true)
        AccountUser.create!(user: @user, account: Account.default, role: Role.get_built_in_role('AccountAdmin'))
        RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: Role.get_built_in_role('TeacherEnrollment'), account: Account.default)
        enrollments = @user.manageable_enrollments_by_permission(:manage_calendar)
        expect(enrollments).to match_array([student_enrollment2, teacher_enrollment2, @student_enrollment1, @teacher_enrollment1])
      end
    end
  end
end
