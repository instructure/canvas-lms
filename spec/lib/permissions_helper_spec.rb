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

  describe "precalculate_permissions_for_courses" do
    def exclude_reads(permissions_hash)
      Hash[permissions_hash.map{|k, v| [k, v.except(:read, :read_grades, :read_as_admin, :participate_as_student)]}]
    end

    it "should return other course-level (non-standard) permission values for active enrollments" do
      invited_student_enrollment = course_with_student(:active_course => true)
      active_student_enrollment = course_with_student(:user => @user, :active_all => true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      courses = [invited_student_enrollment.course, active_student_enrollment.course, teacher_enrollment.course]
      expect(@user.precalculate_permissions_for_courses(courses, [:manage_calendar])).to eq({
        invited_student_enrollment.global_course_id => {:manage_calendar => false, :read_as_admin => false},
        active_student_enrollment.global_course_id => {:manage_calendar => false, :read => true, :read_grades => true, :participate_as_student => true, :read_as_admin => false},
        teacher_enrollment.global_course_id => {:manage_calendar => true, :read => true, :read_as_admin => true}
      })
    end

    it "should still let concluded term teachers read_as_admin" do
      concluded_teacher_term = Account.default.enrollment_terms.create!(:name => "concluded")
      concluded_teacher_term.set_overrides(Account.default, 'TeacherEnrollment' => { start_at: '2014-12-01', end_at: '2014-12-31' })
      concluded_teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      @course.update_attributes(:enrollment_term => concluded_teacher_term)

      expect(@user.precalculate_permissions_for_courses([@course], [:manage_calendar])).to eq({
        concluded_teacher_enrollment.global_course_id => {:manage_calendar => false, :read => true, :read_as_admin => true}
      })
    end

    it 'should return true for enrollments that have permission from a direct account override' do
      student_enrollment = course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: student_role, account: Account.default)
      RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: teacher_role, account: Account.default)

      courses = [student_enrollment.course, teacher_enrollment.course]
      expect(exclude_reads(@user.precalculate_permissions_for_courses(courses, [:manage_calendar]))).to eq({
        student_enrollment.global_course_id => {:manage_calendar => true},
        teacher_enrollment.global_course_id => {:manage_calendar => false}
      })
    end

    it 'should return true for enrollments that have permission from an ancestor account override' do
      root_account = Account.default
      sub_account1 = Account.create!(name: 'Sub-account 1', parent_account: root_account)
      sub_account2 = Account.create!(name: 'Sub-account 2', parent_account: sub_account1)
      student_enrollment1 = course_with_student(account: Account.default, active_all: true)
      student_enrollment2 = course_with_student(user: @user, account: sub_account2, active_all: true)
      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: student_role, account: sub_account1)

      courses = [student_enrollment1.course, student_enrollment2.course]
      expect(exclude_reads(@user.precalculate_permissions_for_courses(courses, [:manage_calendar]))).to eq({
        student_enrollment1.global_course_id => {:manage_calendar => false},
        student_enrollment2.global_course_id => {:manage_calendar => true}
      })
    end

    it 'should only return true for enrollments that have permission for the given override' do
      student_enrollment = course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      RoleOverride.create!(permission: 'manage_grades', enabled: true, role: student_role, account: Account.default) # can't actually turn manage_grades on for students
      RoleOverride.create!(permission: 'manage_grades', enabled: false, role: teacher_role, account: Account.default)

      courses = [student_enrollment.course, teacher_enrollment.course]
      expect(exclude_reads(@user.precalculate_permissions_for_courses(courses, [:manage_calendar, :manage_grades]))).to eq({
        student_enrollment.global_course_id => {:manage_calendar => false, :manage_grades => false},
        teacher_enrollment.global_course_id => {:manage_calendar => true, :manage_grades => false}
      })
    end

    it 'should return true for enrollments that have permission from an account role' do
      student_enrollment = course_with_student(active_all: true)
      teacher_enrollment = course_with_teacher(user: @user, active_all: true)
      custom_role = custom_account_role('OverrideTest', account: Account.default)
      @user.account_users.create!(account: Account.default, role: custom_role)

      courses = [student_enrollment.course, teacher_enrollment.course]
      expect(exclude_reads(@user.precalculate_permissions_for_courses(courses, [:manage_calendar, :manage_grades]))).to eq({
        student_enrollment.global_course_id => {:manage_calendar => false, :manage_grades => false},
        teacher_enrollment.global_course_id => {:manage_calendar => true, :manage_grades => true}
      })

      RoleOverride.create!(permission: 'manage_calendar', enabled: true, role: custom_role, account: Account.default)
      expect(exclude_reads(@user.precalculate_permissions_for_courses(courses, [:manage_calendar, :manage_grades]))).to eq({
        student_enrollment.global_course_id => {:manage_calendar => true, :manage_grades => false},
        teacher_enrollment.global_course_id => {:manage_calendar => true, :manage_grades => true}
      })
    end

    it "should work with future restricted permissions" do
      invited_student_enrollment = course_with_student(:active_course => true)
      expect(invited_student_enrollment).to be_invited
      active_student_enrollment = course_with_student(:user => @user, :active_all => true)

      courses = [invited_student_enrollment.course, active_student_enrollment.course]
      expect(exclude_reads(@user.precalculate_permissions_for_courses(courses, [:read_roster, :post_to_forum]))).to eq({
        invited_student_enrollment.global_course_id => {:read_roster => true, :post_to_forum => false},
        active_student_enrollment.global_course_id => {:read_roster => true, :post_to_forum => true}
      })
    end

    it "should work with unenrolled account admins" do
      @course1 = course_factory
      sub_account = Account.default.sub_accounts.create!
      @course2 = course_factory(:account => sub_account)
      account_admin_user(:active_all => true)
      result = @user.precalculate_permissions_for_courses([@course1, @course2], SectionTabHelper::PERMISSIONS_TO_PRECALCULATE)
      expected = Hash[SectionTabHelper::PERMISSIONS_TO_PRECALCULATE.map{|p| [p, true]}] # should be true for everything
      expect(result).to eq({@course1.global_id => expected, @course2.global_id => expected})
    end

    it "should work with concluded-available permissions" do
      RoleOverride.create!(permission: 'moderate_forum', enabled: true, role: student_role, account: Account.default)
      concluded_student_enrollment = course_with_student(:active_all => true)
      @course.update_attributes(:start_at => 1.month.ago, :conclude_at => 2.weeks.ago, :restrict_enrollments_to_course_dates => true)
      expect(concluded_student_enrollment.reload).to be_completed

      concluded_teacher_term = Account.default.enrollment_terms.create!(:name => "concluded")
      concluded_teacher_term.set_overrides(Account.default, 'TeacherEnrollment' => { start_at: '2014-12-01', end_at: '2014-12-31' })

      concluded_teacher_enrollment = course_with_teacher(:user => @user, :active_all => true)
      @course.update_attributes(:enrollment_term => concluded_teacher_term)
      expect(concluded_teacher_enrollment.reload).to be_completed

      active_student_enrollment = course_with_student(:user => @user, :active_all => true)

      courses = [concluded_student_enrollment.course, concluded_teacher_enrollment.course, active_student_enrollment.course]
      expect(exclude_reads(@user.precalculate_permissions_for_courses(courses, [:moderate_forum, :read_forum, :post_to_forum]))).to eq({
        concluded_student_enrollment.global_course_id => {:moderate_forum => false, :read_forum => true, :post_to_forum => false}, # concluded students can't post
        concluded_teacher_enrollment.global_course_id => {:moderate_forum => false, :read_forum => true, :post_to_forum => true}, # concluded teachers can
        active_student_enrollment.global_course_id => {:moderate_forum => true, :read_forum => true, :post_to_forum => true} # active student can do all of it
      })
    end

    context "sharding" do
      specs_require_sharding

      it "should work across shards" do
        @shard1.activate do
          @another_account = Account.create!
          @student_enrollment1 = course_with_student(active_all: true, account: @another_account)
          @teacher_enrollment1 = course_with_teacher(user: @user, active_all: true, account: @another_account)
          @user.account_users.create!(account: @another_account, role: Role.get_built_in_role('AccountAdmin'))
          RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: Role.find_by(name: 'TeacherEnrollment'), account: @another_account)
          RoleOverride.create!(permission: 'moderate_forum', enabled: true, role: Role.find_by(name: 'StudentEnrollment'), account: @another_account)
        end
        student_enrollment2 = course_with_student(user: @user, active_all: true)
        teacher_enrollment2 = course_with_teacher(user: @user, active_all: true)
        AccountUser.create!(user: @user, account: Account.default, role: Role.get_built_in_role('AccountAdmin'))
        RoleOverride.create!(permission: 'manage_calendar', enabled: false, role: Role.get_built_in_role('TeacherEnrollment'), account: Account.default)

        courses = @user.enrollments.shard(@user).to_a.map(&:course)
        permissions = [:manage_calendar, :moderate_forum, :manage_grades]
        all_data = @user.precalculate_permissions_for_courses(courses, permissions)
        courses.each do |course|
          permissions.each do |permission|
            expect(all_data[course.global_id][permission]).to eq course.grants_right?(@user, permission)
          end
        end
      end

      it "should not try to precalculate for a cross-shard admin" do
        @shard1.activate do
          @another_account = Account.create!
          @cs_course = course_factory(active_all: true, account: @another_account)
        end
        site_admin_user(:active_all => true)
        expect(@user.precalculate_permissions_for_courses([@cs_course], [:read_forum])).to eq nil
      end
    end
  end
end
