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

require_relative "../pages/gradebook_history_page"
require_relative "../setup/gb_history_search_setup"

describe "Gradebook History Page" do
  include_context "in-process server selenium tests"
  include GradebookHistorySetup
  include CustomScreenActions

  context "shows the results table for a valid search" do
    before(:once) do
      gb_history_setup(2)
    end

    before do
      user_session(@teacher)
      GradeBookHistory.visit(@course)
      wait_for_ajaximations
    end

    it "with student name input and typeahead selection", priority: "1" do
      student_name = @course.students.first.name
      GradeBookHistory.search_with_student_name(
        student_name[0...3], student_name
      )
      expect(GradeBookHistory.check_table_for_student_name(student_name)).to be true
    end

    it "with grader name input and typeahead selection", priority: "1" do
      GradeBookHistory.search_with_grader_name(
        @teacher.email
      )
      expect(GradeBookHistory.check_table_for_grader_name(@teacher.email)).to be true
    end

    it "with all assignment name and typeahead selection", priority: "1" do
      GradeBookHistory.search_with_assignment_name(
        @assignment_past_due_day.title
      )
      expect(GradeBookHistory.check_table_for_assignment_name(@assignment_past_due_day.title)).to be true
    end

    it "and the current grade column has the same grade as related grade history rows", priority: "1" do
      expect(GradeBookHistory.check_current_col_for_history("assignment two")).to be true
    end
  end

  context "discussion_checkpoints" do
    before do
      Account.default.enable_feature!(:discussion_checkpoints)
    end

    it "shows the results table with discussion checkpoint info" do
      course_with_teacher_logged_in
      student_in_course(active_all: true)

      discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")

      c1 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        points_possible: 5,
        dates: [{ type: "everyone", due_at: 1.week.from_now }]
      )

      c2 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: discussion,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        points_possible: 15,
        replies_required: 3,
        dates: [{ type: "everyone", due_at: 1.week.from_now }]
      )

      c1.grade_student(@course.students.first, grade: 5, grader: @teacher)
      c2.grade_student(@course.students.first, grade: 15, grader: @teacher)

      GradeBookHistory.visit(@course)
      wait_for_ajaximations
      expect(fj("span:contains('checkpointed discussion (Reply to Topic)')")).to be_present
      expect(fj("span:contains('checkpointed discussion (Required Replies)')")).to be_present
    end
  end
end
