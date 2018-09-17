#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../common'

describe "master courses - settings" do
  include_context "in-process server selenium tests"

  before :once do
    @account = Account.default
    @account.enable_feature!(:master_courses)
    @test_course = course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@test_course)
  end

  before :each do
    admin_logged_in
  end

  it "blueprint course selected in settings", priority: "1", test_id: 3097363 do
    get "/courses/#{@test_course.id}/settings"
    expect(is_checked('input[type=checkbox][name=course[blueprint]]')).to be_truthy
  end

  it "blueprint course un-selected in settings", priority: "1", test_id: 3077134 do
    get "/courses/#{@test_course.id}/settings"
    fj('label:contains("Enable course as a Blueprint Course")').click
    wait_for_ajaximations
    submit_form('#course_form')
    wait_for_ajaximations
    expect(MasterCourses::MasterTemplate).not_to be_is_master_course @course
    expect(is_checked('input[type=checkbox][name=course[blueprint]]')).not_to be_truthy
  end

  it "leaves box unchecked for non-blueprint course", priority: "1", test_id: 3138089 do
    MasterCourses::MasterTemplate.remove_as_master_course(@test_course)
    get "/courses/#{@test_course.id}/settings"
    expect(f('input[name="course[blueprint]"]').attribute('checked')).to be_nil
  end

  it "prevents creating a blueprint course from associated course", priority: "2", test_id: 3097364 do
    @associated_course = @template.add_child_course!(course_factory(name: "ac1", active_all: true)).child_course
    get "/courses/#{@associated_course.id}/settings"
    expect(f('.disabled_message')).to be
  end

  it "prevents blueprinting a course with students", priority: "1", test_id: 3097365 do
    student1 = user_with_pseudonym(active_user: true, username: 'student@example.com')
    course2 = course_factory(active_all: true)
    course2.enroll_user(student1, "StudentEnrollment", enrollment_state: 'active')
    get "/courses/#{course2.id}/settings"
    expect(f('.disabled_message')).to be
  end

  it "prevents adding students to blueprint course", priority: "1", test_id: 3078983 do
    get "/courses/#{@course.id}/users"
    f('#addUsers').click
    expect(f('#peoplesearch_select_role')).not_to include_text("Student")
  end

  it "enables blueprint setting based on user permission", priority: 2, test_id: 3046498 do
    role1 = @account.roles.create!(name: "normal admin", base_role_type: "AccountMembership")
    @account.role_overrides.create!(role: role1, permission: :manage_courses, enabled: true)

    role2 = @account.roles.create!(name: "blueprint admin", base_role_type: "AccountMembership")
    @account.role_overrides.create!(permission: :manage_courses, enabled: true, role: role2)
    @account.role_overrides.create!(permission: :manage_master_courses, enabled: true, role: role2)

    normal_admin = account_admin_user(role: role1, name: "Anakin")
    blueprint_admin = account_admin_user(role: role2, name: "Obi-Wan")

    user_session(normal_admin)
    get "/courses/#{@test_course.id}/settings"
    expect(f('#course_blueprint')).to include_text("Yes")

    user_session(blueprint_admin)
    get "/courses/#{@test_course.id}/settings"
    expect(fj('.bcs_check-box:contains("Enable course as a Blueprint Course")')).to be_displayed
  end
end
