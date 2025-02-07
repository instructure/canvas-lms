# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/student_planner_page"

describe "student planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    course_with_teacher(active_all: true, new_user: true, course_name: "Planner Course")
    @student1 = User.create!(name: "Student 1")
    @course.enroll_student(@student1).accept!
  end

  before do
    user_session(@student1)
  end

  context "discussion checkpoints/sub_assignments" do
    before :once do
      @course.account.enable_feature!(:discussion_checkpoints)
      @reply_to_topic, @reply_to_entry = graded_discussion_topic_with_checkpoints(context: @course, title: "Discussion with Checkpoints")
    end

    it "enables the checkbox when a discussion checkpoint is completed", priority: "1" do
      @reply_to_topic.submit_homework(@student1, body: "checkpoint submission for #{@student1.name}")
      go_to_list_view
      expect(planner_app_div).to contain_jqcss('span:contains("Show 1 completed item")')
    end

    it "shows submitted tag for a discussion checkpoint that has submissions", priority: "1" do
      @reply_to_entry.submit_homework(@student1, body: "checkpoint submission for #{@student1.name}")
      go_to_list_view
      # Student planner shows submitted discussion checkpoints as completed. Expand to see the checkpoint
      expand_completed_item
      validate_pill("Submitted")
    end

    it "shows new grades tag for a discussion checkpoint that is graded", priority: "1" do
      @reply_to_topic.grade_student(@student1, grade: 10, grader: @teacher)
      go_to_list_view
      validate_pill("Graded")
    end

    it "shows new feedback tag for a discussion checkpoint that has feedback", priority: "1" do
      @topic.assignment.submission_for_student(@student1).add_comment(user: @teacher, comment: "nice work")
      go_to_list_view
      validate_pill("Feedback")
    end

    it "shows feedback for a discussion checkpoint that has feedback", priority: "1" do
      @topic.assignment.submission_for_student(@student1).add_comment(user: @teacher, comment: "nice work")
      go_to_list_view
      validate_feedback("nice work")
    end

    it "shows missing tag for a discussion checkpoint with missing submissions", priority: "1" do
      @reply_to_topic.due_at = 2.weeks.ago
      @reply_to_topic.save!
      go_to_list_view
      force_click(load_prior_button_selector)
      expect(planner_app_div).to be_displayed
      expect(course_assignment_link(@course.name, planner_app_div)).to be_displayed
      validate_pill("Missing")
    end
  end
end
