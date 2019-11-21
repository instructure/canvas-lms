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
require_relative './pages/courses_home_page'

describe 'course wizard' do
  include_context "in-process server selenium tests"
  include CoursesHomePage

  before(:each) do
    course_with_teacher_logged_in
  end

  it "should open up the choose home page dialog from the wizard" do
    skip('ADMIN-3018')

    go_to_checklist

    choose_a_course_home_page
    wait_for_ajaximations
    modal = fj("h2:contains('Choose Course Home Page')")
    expect(modal).to be_displayed
  end

  it "should have the correct initial state" do
    skip('ADMIN-3018')

    go_to_checklist

    expect(incomplete_checklist_item('content_import')).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector('content_import'))
    expect(incomplete_checklist_item('add_assignments')).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector('add_assignments'))
    expect(incomplete_checklist_item('add_students')).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector('add_students'))
    expect(incomplete_checklist_item('add_files')).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector('add_files'))
    expect(incomplete_checklist_item('select_navigation')).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector('select_navigation'))

    expect(completed_checklist_item('home_page')).to be_displayed

    expect(incomplete_checklist_item('course_calendar')).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector('course_calendar'))
    expect(incomplete_checklist_item('add_tas')).to be_displayed
    expect(f("#content")).not_to contain_css(completed_checklist_item_selector('add_tas'))
  end

  it "should complete 'Add Course Assignments' checklist item" do
    skip('ADMIN-3018')
    @course.assignments.create({name: "Test Assignment"})
    go_to_checklist
    expect(completed_checklist_item('add_assignments')).to be_displayed
  end

  it "should complete 'Add Students to the Course' checklist item" do
    skip('ADMIN-3018')
    student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
    student_in_course(:user => student, :active_all => 1)
    go_to_checklist
    expect(completed_checklist_item('add_students')).to be_displayed
  end

  it "should complete 'Select Navigation Links' checklist item" do
    skip_if_chrome('research - Over the time threshold')

    # Navigate to Navigation tab
    go_to_checklist

    select_navigation_links

    wait_for_ajaximations

    # Modify Navigation
    f('#navigation_tab').click
    f('.navitem.enabled.modules .al-trigger.al-trigger-gray').click
    f('.navitem.enabled.modules .admin-links .disable_nav_item_link').click
    f('#tab-navigation .btn').click

    go_to_checklist

    expect(completed_checklist_item('select_navigation')).to be_displayed
  end

  it "should complete 'Add Course Calendar Events' checklist item" do
    skip_if_chrome('research - Over the time threshold')

    # Navigate to Calendar tab
    go_to_checklist
    add_course_calendar_events

    # Add Event
    f("#create_new_event_link").click
    wait_for_ajaximations
    replace_content(f('#edit_calendar_event_form #calendar_event_title'), "Event")
    f("#edit_calendar_event_form button.event_button").click
    wait_for_ajaximations

    go_to_checklist

    expect(completed_checklist_item('course_calendar')).to be_displayed
  end

  it "should complete 'Publish the Course' checklist item" do
    skip_if_chrome('research - Over the time threshold')

    # Publish from Checklist
    go_to_checklist

    publish_the_course

    go_to_checklist

    expect(completed_checklist_item('publish_course')).to be_displayed
  end
end
