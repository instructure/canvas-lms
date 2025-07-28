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
#

require_relative "../../common"

describe "Course Grading Periods" do
  let(:period_helper) { Factories::GradingPeriodHelper.new }
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }

  include_examples "in-process server selenium tests"

  context "with grading periods" do
    before do
      course_with_teacher_logged_in
    end

    it "shows grading periods created at the course-level", priority: "1" do
      @course_grading_period = period_helper.create_with_group_for_course(@course)
      get "/courses/#{@course.id}/grading_standards"
      period_title = f("#period_title_#{@course_grading_period.id}")
      expect(period_title).to have_value(@course_grading_period.title)
    end

    it "allows grading periods to be deleted", priority: "1" do
      group = group_helper.legacy_create_for_course(@course)
      period_helper.create_with_weeks_for_group(group, 5, 3)
      period_helper.create_with_weeks_for_group(group, 3, 1)
      get "/courses/#{@course.id}/grading_standards"

      # Wait for the page to load and elements to be present
      wait_for_ajaximations
      expect(ff(".grading-period").length).to be 2

      # Click the delete button and confirm deletion
      delete_button = f(".icon-delete-grading-period")
      expect(delete_button).to be_displayed
      expect(delete_button).to be_enabled

      driver.execute_script("window.confirm = function() { return true; }")
      delete_button.click

      # Wait for the delete operation to complete
      wait_for_ajaximations
      expect(ff(".grading-period").length).to be 1
    end

    it "allows updating grading periods", priority: "1" do
      period_helper.create_with_group_for_course(@course)
      get "/courses/#{@course.id}/grading_standards"

      # Wait for the page to load and elements to be present
      wait_for_ajaximations

      # Wait for the update button to be present and enabled
      update_button = f("#update-button")
      expect(update_button).to be_displayed
      expect(update_button).to be_enabled
    end
  end
end

# there is a lot of repeated code in the inheritance tests, since we are testing 3 roles on 3 pages
# the way this works will change soon (MGP version 3), so it makes more sense to wait for these
# changes before refactoring these tests
describe "Course Grading Periods Inheritance" do
  let(:end_date) { format_date_for_view(4.months.from_now - 1.day) }
  let(:start_date) { format_date_for_view(3.months.from_now) }
  let(:title) { "hi" }

  include_examples "in-process server selenium tests"

  before do
    course_with_admin_logged_in
    @account = @course.root_account

    course_with_teacher(course: @course, name: "teacher", active_enrollment: true)
    @account_course = @course
    @account_teacher = @teacher
  end

  it "reads course grading periods", priority: "1" do
    user_session @account_teacher
    course_grading_period = Factories::GradingPeriodHelper.new.create_with_group_for_course(@course)
    get "/courses/#{@account_course.id}/grading_standards"
    expect(ff(".grading-period").length).to be(1)
    expect(f("#period_title_#{course_grading_period.id}")).to have_value(course_grading_period.title)
  end
end
