# frozen_string_literal: true

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

require_relative "../common"
require_relative "pages/courses_home_page"
require_relative "pages/course_settings_page"
require_relative "pages/course_settings_navigation_page_component"
require_relative "pages/course_left_nav_page_component"
require_relative "../calendar/pages/calendar_page"

describe "course wizard" do
  include_context "in-process server selenium tests"
  include CoursesHomePage
  include CourseSettingsPage
  include CourseSettingsNavigationPageComponent
  include CourseLeftNavPageComponent
  include CalendarPage

  before do
    course_with_teacher_logged_in
  end

  it "opens up the choose home page dialog from the wizard" do
    skip("ADMIN-3018")

    go_to_checklist

    choose_a_course_home_page
    wait_for_ajaximations
    modal = fj("h2:contains('Choose Course Home Page')")
    expect(modal).to be_displayed
  end

  it "has the correct initial state" do
    skip("ADMIN-3018")

    go_to_checklist

    expect(incomplete_checklist_item("content_import")).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector("content_import"))
    expect(incomplete_checklist_item("add_assignments")).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector("add_assignments"))
    expect(incomplete_checklist_item("add_students")).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector("add_students"))
    expect(incomplete_checklist_item("add_files")).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector("add_files"))
    expect(incomplete_checklist_item("select_navigation")).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector("select_navigation"))

    expect(completed_checklist_item("home_page")).to be_displayed

    expect(incomplete_checklist_item("course_calendar")).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector("course_calendar"))
    expect(incomplete_checklist_item("add_tas")).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector("add_tas"))
  end

  it "completes 'Add Course Assignments' checklist item" do
    skip("ADMIN-3018")
    @course.assignments.create({ name: "Test Assignment" })
    go_to_checklist
    expect(completed_checklist_item("add_assignments")).to be_displayed
  end

  it "completes 'Add Students to the Course' checklist item" do
    skip("ADMIN-3018")
    student = user_with_pseudonym(username: "student@example.com", active_all: 1)
    student_in_course(user: student, active_all: 1)
    go_to_checklist
    expect(completed_checklist_item("add_students")).to be_displayed
  end

  it "completes 'Select Navigation Links' checklist item" do
    skip("ADMIN-3018")
    # Navigate to Navigation tab
    go_to_checklist
    select_navigation_links
    wait_for_ajaximations

    # Modify Navigation (But not really, you just need to visit and save)
    visit_navigation_tab
    save_course_navigation

    # head back to course wizard and verify it is checked off
    visit_course_home_link
    go_to_checklist
    expect(completed_checklist_item("select_navigation")).to be_displayed
  end

  it "completes 'Add Course Calendar Events' checklist item" do
    skip("ADMIN-3018")

    # Navigate to Calendar tab
    go_to_checklist
    add_course_calendar_events

    # Add Event
    create_new_calendar_event

    add_calendar_event_title("Event")

    submit_calendar_event_changes

    go_to_checklist

    expect(completed_checklist_item("course_calendar")).to be_displayed
  end

  it "completes 'Publish the Course' checklist item" do
    skip("ADMIN-3018")

    # Publish from Checklist
    go_to_checklist

    publish_the_course

    go_to_checklist

    expect(completed_checklist_item("publish_course")).to be_displayed
  end
end
