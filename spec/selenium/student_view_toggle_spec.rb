# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "student view toggle" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:easy_student_view)
    course_with_teacher :active_all => true
  end

  before :each do
    user_session @teacher
  end

  def page_header
    f(".ic-app-nav-toggle-and-crumbs")
  end

  def student_view_toggle
    f("a#easy_student_view")
  end

  it "should be visible from course home with a title" do
    get "/courses/#{@course.id}"
    expect(student_view_toggle).to be_displayed
    expect(student_view_toggle).to have_attribute("title", "Student View")
  end

  it "should redirect to student view on click from assignments index" do
    get "/courses/#{@course.id}/assignments"
    expect(student_view_toggle).to be_displayed
    student_view_toggle.click
    expect(f("body")).to have_class "is-masquerading-or-student-view"
  end

  it "should not be visible from course settings page" do
    get "/courses/#{@course.id}/settings"
    expect(page_header).not_to contain_css("#easy_student_view")
  end

  it "should not be visible from pages that have been disabled by instructor" do
    @course.update_attribute(:tab_configuration, [{'id'=>Course::TAB_QUIZZES, 'hidden'=>true}])
    get "/courses/#{@course.id}/quizzes"
    expect(page_header).not_to contain_css("#easy_student_view")
  end

  it "should not be visible to students" do
    course_with_student_logged_in
    get "/courses/#{@course.id}"
    expect(page_header).not_to contain_css("#easy_student_view")
  end

  it "should hide and show on assignments index when switching to and from bulk edit mode" do
    Account.site_admin.enable_feature!(:assignment_bulk_edit)
    get "/courses/#{@course.id}/assignments"
    expect(student_view_toggle).to be_displayed
    f("#course_assignment_settings_link").click
    f("#requestBulkEditMenuItem").click
    expect(student_view_toggle).not_to be_displayed
    fj("#bulkEditRoot button:contains('Cancel')").click
    expect(student_view_toggle).to be_displayed
  end
end
