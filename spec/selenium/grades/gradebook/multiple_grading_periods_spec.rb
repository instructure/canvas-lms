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
require_relative "../pages/gradebook_page"
require_relative "../../helpers/gradebook_common"

describe "interaction with grading periods" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
  let(:get_gradebook) { get "/courses/#{@course.id}/gradebook" }
  let(:now) { Time.zone.now }

  context "gradebook" do
    before :once do
      gradebook_data_setup(grading_periods: [:future, :current])

      # Remove sections, as there is a bug when attempting to click on the
      # Grading Period filter option. The Section filter option is clicked
      # instead, for reasons unknown.
      @course.course_sections.each do |section|
        section.destroy unless section.default_section?
      end
    end

    before do
      user_session(@teacher)
    end

    after do
      clear_local_storage
    end

    it "displays the correct grading period based on the GET param" do
      future_period = @course.grading_periods.detect { |gp| gp.start_date.future? }
      get "/courses/#{@course.id}/gradebook?grading_period_id=#{future_period.id}"
      Gradebook.select_view_dropdown
      Gradebook.select_filters
      Gradebook.select_view_filter("Grading Periods")
      expect(Gradebook.grading_period_dropdown).to have_value(future_period.title)
    end

    it "displays All Grading Periods when grading period id is set to 0" do
      get "/courses/#{@course.id}/gradebook?grading_period_id=0"
      Gradebook.select_view_dropdown
      Gradebook.select_filters
      Gradebook.select_view_filter("Grading Periods")
      expect(Gradebook.grading_period_dropdown).to have_value("All Grading Periods")
    end

    it "displays the current grading period without a GET param" do
      current_period = @course.grading_periods.detect { |gp| gp.start_date.past? && gp.end_date.future? }
      get "/courses/#{@course.id}/gradebook"
      Gradebook.select_view_dropdown
      Gradebook.select_filters
      Gradebook.select_view_filter("Grading Periods")
      expect(Gradebook.grading_period_dropdown).to have_value(current_period.title)
    end

    context "using grading period dropdown" do
      it "displays current grading period on load", priority: "2" do
        get_gradebook
        element = ff(".slick-header-column a").select { |a| a.text == "assignment three" }
        expect(element.first).to be_displayed
      end

      it "filters assignments when different grading periods selected", priority: "2" do
        get_gradebook
        Gradebook.select_view_dropdown
        Gradebook.select_filters
        Gradebook.select_view_filter("Grading Periods")
        Gradebook.select_grading_period("Course Period 1: future period")
        element = ff(".slick-header-column a").select { |a| a.text == "second assignment" }
        expect(element.first).to be_displayed
      end

      it "displays all assignments when all grading periods selected", priority: "2" do
        get_gradebook
        Gradebook.select_view_dropdown
        Gradebook.select_filters
        Gradebook.select_view_filter("Grading Periods")
        Gradebook.select_grading_period("All Grading Periods")

        element = ff(".slick-header-column a").select { |a| a.text == "assignment three" }
        expect(element.first).to be_displayed
        element = ff(".slick-header-column a").select { |a| a.text == "second assignment" }
        expect(element.first).to be_displayed
      end
    end
  end

  context "grading schemes" do
    let(:account) { Account.default }
    let(:admin) { account_admin_user(account:) }
    let(:test_course) { account.courses.create!(name: "New Course") }

    it "disables adding during edit mode on course page", priority: "1" do
      user_session(admin)
      get "/courses/#{test_course.id}/grading_standards"
      f("button.add_standard_button").click
      expect(f("input.scheme_name")).not_to be_nil
      expect(f("button.add_standard_button")).to have_class("disabled")
    end

    it "disables adding during edit mode on account page", priority: "1" do
      user_session(admin)
      get "/accounts/#{account.id}/grading_standards"
      f('#react_grading_tabs a[href="#grading-standards-tab"]').click
      f("button.add_standard_button").click
      expect(f("input.scheme_name")).not_to be_nil
      expect(f("button.add_standard_button")).to have_class("disabled")
    end

    context "assignment index page" do
      let(:account) { Account.default }
      let(:teacher) { user_factory(active_all: true) }
      let!(:enroll_teacher) { test_course.enroll_user(teacher, "TeacherEnrollment", enrollment_state: "active") }
      let!(:grading_period_group) { group_helper.legacy_create_for_course(test_course) }
      let!(:course_grading_period_current) do
        grading_period_group.grading_periods.create!(
          title: "Course Grading Period 1",
          start_date: 1.day.ago(now),
          end_date: 4.weeks.from_now(now)
        )
      end
      let!(:course_grading_period_past) do
        grading_period_group.grading_periods.create!(
          title: "Course Grading Period 2",
          start_date: 4.weeks.ago(now),
          end_date: 1.day.ago(now)
        )
      end
      let!(:assignment) do
        test_course.assignments.create!(
          title: "Assignment 1",
          due_at: 1.day.ago(now),
          points_possible: 10,
          workflow_state: "published"
        )
      end

      it "lists an assignment from a previous grading period", priority: "2", test_course: 381_145 do
        user_session(teacher)
        get "/courses/#{test_course.id}/assignments"
        expect(f("#assignment_#{assignment.id} a.ig-title")).to include_text("Assignment 1")
      end

      it "lists an assignment from a current grading period when due date is updated", priority: "2", test_course: 576_764 do
        assignment.update(due_at: 3.days.from_now(now))
        user_session(teacher)
        get "/courses/#{test_course.id}/assignments"
        expect(f("#assignment_#{assignment.id} a.ig-title")).to include_text("Assignment 1")
      end
    end
  end

  context "student view" do
    let(:account) { Account.default }
    let(:test_course) { account.courses.create!(name: "New Course") }
    let(:student) { user_factory(active_all: true) }
    let(:teacher) { user_factory(active_all: true) }
    let!(:enroll_teacher) { test_course.enroll_teacher(teacher) }
    let!(:enroll_student) { test_course.enroll_user(student, "StudentEnrollment", enrollment_state: "active") }
    let!(:grading_period_group) { group_helper.legacy_create_for_course(test_course) }
    let!(:course_grading_period_1) do
      grading_period_group.grading_periods.create!(
        title: "Course Grading Period 1",
        start_date: 1.day.ago(now),
        end_date: 3.weeks.from_now(now)
      )
    end
    let!(:course_grading_period_2) do
      grading_period_group.grading_periods.create!(
        title: "Course Grading Period 2",
        start_date: 4.weeks.from_now(now),
        end_date: 7.weeks.from_now(now)
      )
    end
    let!(:assignment1) { test_course.assignments.create!(title: "Assignment 1", due_at: 3.days.from_now(now), points_possible: 10) }
    let!(:assignment2) { test_course.assignments.create!(title: "Assignment 2", due_at: 6.weeks.from_now(now), points_possible: 10) }
    let!(:grade_assignment1) { assignment1.grade_student(student, grade: 8, grader: teacher) }

    before do
      test_course.offer!
      user_session(student)
      get "/courses/#{test_course.id}/grades"
    end

    it "displays the current grading period and assignments in grades page", priority: "1" do
      expect(f("#grading_period_select_menu").attribute("value")).to eq "Course Grading Period 1"
      expect(f("#submission_#{assignment1.id} th a")).to include_text("Assignment 1")
    end

    it "updates assignments when a different period is selected in grades page", priority: "1" do
      click_option("#grading_period_select_menu", "Course Grading Period 2")
      expect_new_page_load { f("#apply_select_menus").click }
      expect(fj("#submission_#{assignment2.id} th a")).to include_text("Assignment 2")
    end

    it "updates assignments when a all periods are selected in grades page", priority: "1" do
      click_option("#grading_period_select_menu", "All Grading Periods")
      expect_new_page_load { f("#apply_select_menus").click }
      expect(fj("#submission_#{assignment1.id} th a")).to include_text("Assignment 1")
      expect(fj("#submission_#{assignment2.id} th a")).to include_text("Assignment 2")
    end
  end
end
