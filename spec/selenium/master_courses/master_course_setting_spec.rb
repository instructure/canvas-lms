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
    expect(f('.disabled_message')).to be
  end

  it "leaves box unchecked for non-blueprint course", priority: "1", test_id: 3138089 do
    MasterCourses::MasterTemplate.remove_as_master_course(@test_course)
    get "/courses/#{@test_course.id}/settings"
    expect(f('input[name="course[blueprint]"]').attribute('checked')).to be_nil
  end

  it "includes Blueprint Courses permission for local admin", priority: "1", test_id: 3138086 do
    get "/accounts/#{@account.id}/permissions"
    f('#account_role_link.ui-tabs-anchor').click()
    expect(driver.find_element(:xpath, "//th[text()[contains(., 'Blueprint')]]")).not_to be nil
  end

  it "prevents creating a blueprint course from associated course", priority: "2", test_id: 3097364 do
    @associated_course = @template.add_child_course!(course_factory(name: "ac1", active_all: true)).child_course
    get "/courses/#{@associated_course.id}/settings"
    expect(f('.disabled_message')).to be
  end

  it "prevents blueprinting a course with students", priority: "1", test_id: 3097365 do
    student1 = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
    course2 = course_factory(active_all: true)
    course2.enroll_user(student1, "StudentEnrollment", :enrollment_state => 'active')
    get "/courses/#{course2.id}/settings"
    expect(f('.disabled_message')).to be
  end
end
