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

# built-in roles are only associated to a root account and have nil for account_id
# and a workflow_state of 'built_in'

require 'spec_helper'

describe 'DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd' do
  before(:once) { @account = account_model(parent_account: Account.default) }

  it "doesn't create role overrides if 'teachers/students can create courses' setting is not enabled" do
    @account.roles.create(name: 'Custom Teacher Role', base_role_type: 'TeacherEnrollment')
    @account.roles.create(name: 'Custom Student Role', base_role_type: 'StudentEnrollment')
    teacher_in_course(active_all: true)
    student_in_course(active_all: true)

    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

    expect(RoleOverride.where(permission: 'manage_courses_add').count).to eq 0
  end

  it "doesn't create role overrides if there are no active enrollments for specified setting" do
    @account.root_account.update(settings: { teachers_can_create_courses: true })
    @account.roles.create(name: 'Custom Teacher Role', base_role_type: 'TeacherEnrollment')

    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

    expect(RoleOverride.where(permission: 'manage_courses_add').count).to eq 0
  end

  it 'skips roles associated to site admin' do
    @account.root_account.update(settings: { teachers_can_create_courses: true })
    @account.roles.create(name: 'Custom Teacher Role', base_role_type: 'TeacherEnrollment')
    @account.roles.create(name: 'Custom Designer Role', base_role_type: 'DesignerEnrollment')
    teacher_in_course(active_all: true)
    designer_in_course(active_all: true)

    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

    expect(
      RoleOverride.where(permission: 'manage_courses_add').map { |ro| ro.root_account.site_admin? }
    ).not_to include(true)
  end

  it 'creates role overrides for all built-in / base roles that are supported' do
    @account.root_account.update(
      settings: {
        teachers_can_create_courses: true,
        students_can_create_courses: true
      }
    )
    @account.roles.create(name: 'Custom Teacher Role', base_role_type: 'TeacherEnrollment')
    @account.roles.create(name: 'Custom Designer Role', base_role_type: 'DesignerEnrollment')
    @account.roles.create(name: 'Custom Student Role', base_role_type: 'StudentEnrollment')
    @account.roles.create(name: 'Custom Observer Role', base_role_type: 'ObserverEnrollment')
    teacher_in_course(active_all: true)
    student_in_course(active_all: true)

    DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

    # four built-in roles on the root account + the additional
    # four custom roles with the same base role type on the sub-account
    expect(RoleOverride.where(permission: 'manage_courses_add').count).to eq 8
  end

  context 'teachers can create courses' do
    it 'creates role overrides for built-in and custom TeacherEnrollment' do
      @account.root_account.update(settings: { teachers_can_create_courses: true })
      @account.roles.create(name: 'Custom Teacher Role', base_role_type: 'TeacherEnrollment')
      teacher_in_course(active_all: true)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

      expect(RoleOverride.where(permission: 'manage_courses_add').count).to eq 3
    end

    it 'creates role overrides for built-in and custom DesignerEnrollment' do
      @account.root_account.update(settings: { teachers_can_create_courses: true })
      @account.roles.create(name: 'Custom Designer Role', base_role_type: 'DesignerEnrollment')
      designer_in_course(active_all: true)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

      expect(RoleOverride.where(permission: 'manage_courses_add').count).to eq 3
    end
  end

  context 'students can create courses' do
    it 'creates role overrides for built-in / base roles StudentEnrollment, ObserverEnrollment' do
      @account.root_account.update(settings: { students_can_create_courses: true })
      @account.roles.create(name: 'Custom Student Role', base_role_type: 'StudentEnrollment')
      student_in_course(active_all: true)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

      expect(RoleOverride.where(permission: 'manage_courses_add').count).to eq 3
    end

    it 'creates role overrides for built-in / base roles ObserverEnrollment, StudentEnrollment' do
      @account.root_account.update(settings: { students_can_create_courses: true })
      @account.roles.create(name: 'Custom Observer Role', base_role_type: 'ObserverEnrollment')
      observer_in_course(active_all: true)

      DataFixup::GranularPermissions::AddRoleOverridesForManageCoursesAdd.run

      expect(RoleOverride.where(permission: 'manage_courses_add').count).to eq 3
    end
  end
end
