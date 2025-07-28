# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../common"
require_relative "pages/new_course_search_page"
require_relative "pages/new_course_add_people_modal"
require_relative "pages/new_course_add_course_modal"
require_relative "pages/course_page"

describe "new account course search" do
  include NewCourseSearchPage
  include NewCourseAddPeopleModal
  include NewCourseAddCourseModal
  include CourseHomePage

  include_context "in-process server selenium tests"

  before :once do
    account_model
    account_admin_user(account: @account, active_all: true)
  end

  before do
    user_session(@user)
  end

  it "does not show the courses tab without permission" do
    @account.role_overrides.create! role: admin_role, permission: "read_course_list", enabled: false

    visit_courses(@account)
    expect(left_navigation).not_to include_text("Courses")
  end

  it "hides courses without enrollments if checked", priority: 1 do
    empty_course = course_factory(account: @account, course_name: "no enrollments")
    not_empty_course = course_factory(account: @account, course_name: "yess enrollments", active_all: true)
    student_in_course(course: not_empty_course, active_all: true)

    visit_courses(@account)

    expect(rows.count).to eq 2
    expect(rows[0]).to include_text(empty_course.name)
    expect(rows[1]).to include_text(not_empty_course.name)
    click_hide_courses_without_students

    expect(rows.count).to eq 1
    expect(rows[0]).to include_text(not_empty_course.name)
    expect(rows[0]).not_to include_text(empty_course.name)
  end

  it "paginates", priority: 1 do
    16.times { |i| @account.courses.create!(name: "course #{i + 1}") }

    visit_courses(@account)

    expect(rows.count).to eq 15
    expect(rows.first).to include_text("course 1")

    expect(course_table).not_to include_text("course 16")
    expect(course_table_navigation).not_to contain_css('button[title="Previous Page"]')

    navigate_to_page("2")

    expect(rows.count).to eq 1
    expect(rows.first).to include_text("course 16")
  end

  it "searches by term", priority: 1 do
    term = @account.enrollment_terms.create!(name: "some term")
    term_course = course_factory(account: @account, course_name: "term course_factory")
    term_course.enrollment_term = term
    term_course.save!

    course_factory(account: @account, course_name: "other course_factory")

    visit_courses(@account)
    select_term(term)

    expect(rows.count).to eq 1
    expect(rows.first).to include_text(term_course.name)
  end

  it "filters terms by search string" do
    %w[Summer Fall Winter Spring].each do |term|
      enrollment_term = @account.enrollment_terms.create!(name: term)
      course = course_factory(account: @account, course_name: "#{term} Course")
      course.enrollment_term = enrollment_term
      course.save!
    end

    visit_courses(@account)
    term_filter = f("#termFilter")
    set_value(term_filter, "s")
    option_list_id = term_filter.attribute("aria-controls")
    expect(ff("##{option_list_id} [role='option']").count).to eq 2
    set_value(term_filter, "spring")
    term = @account.enrollment_terms.where(name: "Spring").first
    wait_for_spinner { fj("##{option_list_id} [role='option']:contains(#{term.name})").click }
    expect(rows.count).to eq 1
    expect(rows.first).to include_text(term.name)
  end

  it "searches by name" do
    match_course = course_factory(account: @account, course_name: "course_factory with a search term")
    course_factory(account: @account, course_name: "diffrient cuorse")

    visit_courses(@account)
    search("search")

    expect(rows.count).to eq 1
    expect(rows.first).to include_text(match_course.name)
  end

  it "brings up course page when clicking name", priority: "1" do
    named_course = course_factory(account: @account, course_name: "named_course")
    named_course.default_view = "feed"
    named_course.save
    visit_courses(@account)

    click_course_link(named_course.name)
    expect(course_header).to include_text named_course.name
  end

  it "searches but not find bogus course", priority: "1" do
    bogus = "jtsdumbthing"
    visit_courses(@account)

    search(bogus)
    expect(results_body).not_to contain_css(results_list_css)
  end

  it "shows teachers" do
    course_factory(account: @account)
    teacher = user_factory(name: "some teacher")
    teacher_in_course(course: @course, user: teacher)

    visit_courses(@account)
    expect(course_teacher_link(teacher)).to include_text(teacher.name)
  end

  it "loads sections in new enrollment dialog" do
    course = course_factory(account: @account)
    visit_courses(@account)

    # doing this after the page loads to ensure that the frontend loads them dynamically
    # when the "+ users" is clicked and not as part of the page load
    sections = ("A".."Z").map { |i| course.course_sections.create!(name: "Test Section #{i}") }

    click_add_users_to_course(@course)
    expect(section_options).to eq(sections.map(&:name))
  end

  it "creates a new course from the 'Add a New Course' dialog", priority: 1 do
    @account.enrollment_terms.create!(name: "Test Enrollment Term")
    subaccount = @account.sub_accounts.create!(name: "Test Sub Account")

    visit_courses(@account)

    # fill out the form
    click_add_course_button
    expect(add_course_modal).to be_displayed
    enter_course_name("Test Course Name")
    enter_reference_code("TCN 101")
    select_subaccount(subaccount)
    select_enrollment_term("Test Enrollment Term")
    submit_new_course

    # make sure it got saved to db correctly
    new_course = Course.last

    expect(new_course.name).to eq("Test Course Name")
    expect(new_course.course_code).to eq("TCN 101")
    expect(new_course.account.name).to eq("Test Sub Account")
    expect(new_course.enrollment_term.name).to eq("Test Enrollment Term")

    # make sure it shows up on the page
    expect(rows.first).to include_text("Test Course Name")
  end

  it "creates a new course from the 'Add a New Course' dialog with only required fields" do
    visit_courses(@account)

    # fill out the form
    click_add_course_button
    expect(add_course_modal).to be_displayed
    enter_course_name("Test Course Name")
    enter_reference_code("TCN 101")
    submit_new_course

    # make sure it got saved to db correctly
    new_course = Course.last

    expect(new_course.name).to eq("Test Course Name")
    expect(new_course.course_code).to eq("TCN 101")
    expect(new_course.account.name).to eq(@account.name)
    expect(new_course.enrollment_term.name).to eq("Default Term")

    # make sure it shows up on the page
    expect(rows.first).to include_text("Test Course Name")
  end

  it "lists course name at top of add user modal", priority: "1" do
    named_course = course_factory(account: @account, course_name: "course factory with name")

    visit_courses(@account)
    click_add_user_button(named_course.name)
    expect(add_people_header).to include_text(named_course.name)
  end

  it "only shows non-admin manageable roles in new enrollment dialog" do
    custom_name = "Custom Student role"
    custom_student_role(custom_name, account: @account)

    @account.role_overrides.create!(permission: "add_ta_to_course", enabled: false, role: admin_role)
    @account.role_overrides.create!(permission: "add_designer_to_course", enabled: false, role: admin_role)
    @account.role_overrides.create!(permission: "add_teacher_to_course", enabled: false, role: admin_role)

    course_factory(account: @account)

    visit_courses(@account)
    click_add_users_to_course(@course)

    expect(add_people_modal).to be_displayed
    expect(role_options).to match_array(["Student", "Observer", custom_name])
  end

  it "shows all admin manageable roles in new enrollment dialog" do
    custom_name = "Custom Student role"
    custom_student_role(custom_name, account: @account)

    course_factory(account: @account)

    visit_courses(@account)
    click_add_users_to_course(@course)

    expect(add_people_modal).to be_displayed
    expect(role_options).to match_array([custom_name, "Designer", "Observer", "Student", "TA", "Teacher"])
  end
end
