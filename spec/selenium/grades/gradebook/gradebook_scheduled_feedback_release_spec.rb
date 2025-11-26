# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../pages/gradebook_page"
require_relative "../pages/assignment_posting_policy_tray_page"
require_relative "../../helpers/gradebook_common"
require_relative "../setup/gradebook_setup"

describe "Gradebook Scheduled Feedback Release" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  before(:once) do
    Account.site_admin.enable_feature!(:scheduled_feedback_releases)
    Account.site_admin.enable_feature!(:assignments_2_student)

    @course = course_factory(active_all: true)
    @teacher = @course.teachers.first
    @student1 = student_in_course(course: @course, active_all: true).user
    @student2 = student_in_course(course: @course, active_all: true).user

    @assignment = @course.assignments.create!(
      title: "Scheduled Release Assignment",
      grading_type: "points",
      points_possible: 10,
      submission_types: "online_text_entry"
    )

    @rubric = @course.rubrics.create!(
      title: "Test Rubric",
      points_possible: 5
    )
    @rubric.data = [
      {
        points: 5,
        description: "Criterion 1",
        id: "crit1",
        long_description: "",
        ratings: [
          { description: "Full Marks", points: 5, id: "rat1" },
          { description: "Partial", points: 2, id: "rat2" }
        ]
      }
    ]
    @rubric.save!
    @rubric_association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: false)
  end

  before do
    user_session(@teacher)
  end

  context "with feature flag disabled" do
    before(:once) do
      Account.site_admin.disable_feature!(:scheduled_feedback_releases)
    end

    it "does not show scheduled release UI components" do
      Gradebook.visit(@course)
      Gradebook.click_grade_posting_policy(@assignment.id)

      AssignmentPostingPolicyTray.select_manually_post

      expect(f("body")).not_to contain_css('[data-testid="scheduled-release-policy"]')
    end
  end

  context "with feature flag enabled" do
    before(:once) do
      Account.site_admin.enable_feature!(:scheduled_feedback_releases)
    end

    describe "UI component rendering" do
      it "shows scheduled release checkbox when manual posting is selected" do
        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post

        expect(AssignmentPostingPolicyTray.schedule_release_checkbox).to be_displayed
      end

      it "hides scheduled release checkbox when automatic posting is selected" do
        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_automatically_post

        expect(f("body")).not_to contain_css('[data-testid="scheduled-release-policy"]')
      end

      it "shows shared and separate schedule radio buttons when checkbox is enabled" do
        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release

        expect(AssignmentPostingPolicyTray.shared_schedule_radio).to be_displayed
        expect(AssignmentPostingPolicyTray.separate_schedule_radio).to be_displayed
      end

      it "shows shared datetime input when shared schedule is selected" do
        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_shared_schedule

        expect(AssignmentPostingPolicyTray.shared_datetime_input).to be_displayed
      end

      it "shows separate datetime inputs when separate schedule is selected" do
        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_separate_schedule

        expect(AssignmentPostingPolicyTray.grades_datetime_input).to be_displayed
        expect(AssignmentPostingPolicyTray.comments_datetime_input).to be_displayed
      end
    end

    describe "shared schedule persistence" do
      it "saves shared scheduled release date and time" do
        future_date = format_date_for_view(2.days.from_now)
        future_time = "11:30 AM"

        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_shared_schedule
        AssignmentPostingPolicyTray.set_shared_schedule(date: future_date, time: future_time)
        AssignmentPostingPolicyTray.click_save

        scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(scheduled_post).not_to be_nil
        expect(scheduled_post.post_comments_at).to eq(scheduled_post.post_grades_at)
      end

      it "persists shared schedule after reopening tray" do
        future_date = format_date_for_view(2.days.from_now)
        future_time = "11:30 AM"

        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_shared_schedule
        AssignmentPostingPolicyTray.set_shared_schedule(date: future_date, time: future_time)
        AssignmentPostingPolicyTray.click_save

        Gradebook.click_grade_posting_policy(@assignment.id)

        expect(AssignmentPostingPolicyTray.schedule_release_checkbox_input.attribute("checked")).to be_truthy
        expect(AssignmentPostingPolicyTray.shared_schedule_radio_input.attribute("checked")).to be_truthy
      end

      it "persists shared schedule after page reload" do
        future_date = format_date_for_view(2.days.from_now)
        future_time = "11:30 AM"

        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_shared_schedule
        AssignmentPostingPolicyTray.set_shared_schedule(date: future_date, time: future_time)
        AssignmentPostingPolicyTray.click_save

        refresh_page
        wait_for_ajaximations

        Gradebook.click_grade_posting_policy(@assignment.id)

        expect(AssignmentPostingPolicyTray.schedule_release_checkbox_input.attribute("checked")).to be_truthy
        expect(AssignmentPostingPolicyTray.shared_schedule_radio_input.attribute("checked")).to be_truthy
      end
    end

    describe "separate schedule persistence" do
      it "saves separate scheduled release dates and times" do
        comments_date = format_date_for_view(1.day.from_now)
        comments_time = "10:00 AM"
        grades_date = format_date_for_view(3.days.from_now)
        grades_time = "2:00 PM"

        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_separate_schedule
        AssignmentPostingPolicyTray.set_comments_schedule(date: comments_date, time: comments_time)
        AssignmentPostingPolicyTray.set_grades_schedule(date: grades_date, time: grades_time)
        AssignmentPostingPolicyTray.click_save

        scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(scheduled_post).not_to be_nil
        expect(scheduled_post.post_comments_at).not_to eq(scheduled_post.post_grades_at)
        expect(scheduled_post.post_comments_at).to be < scheduled_post.post_grades_at
      end

      it "persists separate schedule after reopening tray" do
        comments_date = format_date_for_view(1.day.from_now)
        comments_time = "10:00 AM"
        grades_date = format_date_for_view(3.days.from_now)
        grades_time = "2:00 PM"

        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_separate_schedule
        AssignmentPostingPolicyTray.set_comments_schedule(date: comments_date, time: comments_time)
        AssignmentPostingPolicyTray.set_grades_schedule(date: grades_date, time: grades_time)
        AssignmentPostingPolicyTray.click_save

        Gradebook.click_grade_posting_policy(@assignment.id)

        expect(AssignmentPostingPolicyTray.schedule_release_checkbox_input.attribute("checked")).to be_truthy
        expect(AssignmentPostingPolicyTray.separate_schedule_radio_input.attribute("checked")).to be_truthy
      end

      it "updates separate schedule to new times" do
        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_separate_schedule
        AssignmentPostingPolicyTray.set_comments_schedule(date: format_date_for_view(1.day.from_now), time: "10:00 AM")
        AssignmentPostingPolicyTray.set_grades_schedule(date: format_date_for_view(3.days.from_now), time: "2:00 PM")
        AssignmentPostingPolicyTray.click_save

        initial_scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)

        new_comments_date = format_date_for_view(5.days.from_now)
        new_grades_date = format_date_for_view(7.days.from_now)

        Gradebook.click_grade_posting_policy(@assignment.id)
        AssignmentPostingPolicyTray.set_comments_schedule(date: new_comments_date, time: "11:00 AM")
        AssignmentPostingPolicyTray.set_grades_schedule(date: new_grades_date, time: "3:00 PM")
        AssignmentPostingPolicyTray.click_save

        updated_scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(updated_scheduled_post.id).to eq(initial_scheduled_post.id)
        expect(updated_scheduled_post.post_comments_ran_at).to be_nil
        expect(updated_scheduled_post.post_grades_ran_at).to be_nil
      end
    end

    describe "scheduled release management" do
      it "removes scheduled release when checkbox is unchecked" do
        future_date = format_date_for_view(2.days.from_now)
        future_time = "11:30 AM"

        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_shared_schedule
        AssignmentPostingPolicyTray.set_shared_schedule(date: future_date, time: future_time)
        AssignmentPostingPolicyTray.click_save

        scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(scheduled_post).not_to be_nil

        Gradebook.click_grade_posting_policy(@assignment.id)
        AssignmentPostingPolicyTray.schedule_release_checkbox.click
        AssignmentPostingPolicyTray.click_save

        scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(scheduled_post).to be_nil
      end

      it "switches from shared to separate schedule" do
        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_shared_schedule
        AssignmentPostingPolicyTray.set_shared_schedule(date: format_date_for_view(2.days.from_now), time: "11:30 AM")
        AssignmentPostingPolicyTray.click_save

        initial_scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(initial_scheduled_post.post_comments_at).to eq(initial_scheduled_post.post_grades_at)

        Gradebook.click_grade_posting_policy(@assignment.id)
        AssignmentPostingPolicyTray.select_separate_schedule
        AssignmentPostingPolicyTray.set_comments_schedule(date: format_date_for_view(1.day.from_now), time: "10:00 AM")
        AssignmentPostingPolicyTray.set_grades_schedule(date: format_date_for_view(3.days.from_now), time: "2:00 PM")
        AssignmentPostingPolicyTray.click_save

        updated_scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(updated_scheduled_post.id).to eq(initial_scheduled_post.id)
        expect(updated_scheduled_post.post_comments_at).not_to eq(updated_scheduled_post.post_grades_at)
      end

      it "switches from automatic to manual with scheduled release" do
        @assignment.ensure_post_policy(post_manually: false)

        Gradebook.visit(@course)
        Gradebook.click_grade_posting_policy(@assignment.id)

        AssignmentPostingPolicyTray.select_manually_post
        AssignmentPostingPolicyTray.enable_scheduled_release
        AssignmentPostingPolicyTray.select_shared_schedule
        AssignmentPostingPolicyTray.set_shared_schedule(date: format_date_for_view(2.days.from_now), time: "11:30 AM")
        AssignmentPostingPolicyTray.click_save

        @assignment.reload
        expect(@assignment.post_policy.post_manually).to be true
        scheduled_post = ScheduledPost.find_by(assignment_id: @assignment.id)
        expect(scheduled_post).not_to be_nil
      end
    end
  end
end
