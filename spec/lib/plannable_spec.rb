# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Plannable do
  context "planner_override_for" do
    before :once do
      course_with_student(active_all: true)
    end

    it "returns a regular assignment's override" do
      assignment = assignment_model
      override = assignment.planner_overrides.create!(user: @student)
      expect(assignment.planner_override_for(@student)).to eq override
    end

    it "returns the assignment's associated override" do
      assignment = assignment_model(submission_types: "discussion_topic")
      discussion = assignment.discussion_topic
      discussion_override = discussion.planner_overrides.create!(user: @student)
      expect(assignment.planner_override_for(@student)).to eq discussion_override
    end

    it "returns the assignment's override if the associated object does not have an override" do
      assignment = assignment_model
      assignment_override = assignment.planner_overrides.create!(user: @student)
      assignment.submission_types = "discussion_topic"
      assignment.save!
      expect(assignment.planner_override_for(@student)).to eq assignment_override
    end

    it "prefers the associated object's override if both have an override" do
      assignment = assignment_model
      assignment.planner_overrides.create!(user: @student)
      assignment.submission_types = "discussion_topic"
      assignment.save!
      discussion_override = assignment.discussion_topic.planner_overrides.create!(user: @student)
      expect(assignment.planner_override_for(@student)).to eq discussion_override
    end

    it "does not return deleted overrides" do
      assignment = assignment_model
      override = assignment.planner_overrides.create!(user: @student)
      override.destroy!
      expect(override.workflow_state).to eq "deleted"
      expect(assignment.planner_override_for(@student)).to be_nil
    end

    it "returns overrides for sub_assignments" do
      @course.account.enable_feature!(:discussion_checkpoints)
      reply_to_topic, reply_to_entry = graded_discussion_topic_with_checkpoints(context: @course)
      reply_to_topic_override = PlannerOverride.create!(
        plannable_id: reply_to_topic.id,
        plannable_type: "SubAssignment",
        marked_complete: true,
        user: @student
      )
      expect(reply_to_topic.planner_override_for(@student)).to eq reply_to_topic_override
      reply_to_entry_override = PlannerOverride.create!(
        plannable_id: reply_to_entry.id,
        plannable_type: "SubAssignment",
        marked_complete: true,
        user: @student
      )
      expect(reply_to_entry.planner_override_for(@student)).to eq reply_to_entry_override
    end

    it "returns overrides for peer_review_sub_assignments" do
      @course.account.enable_feature!(:peer_review_allocation_and_grading)
      parent_assignment = @course.assignments.create!(title: "Parent", peer_reviews: true)
      prsa = PeerReviewSubAssignment.create!(parent_assignment:, context: @course, title: "Peer Review", points_possible: 10)
      override = PlannerOverride.create!(
        plannable_id: prsa.id,
        plannable_type: "PeerReviewSubAssignment",
        marked_complete: true,
        user: @student
      )
      expect(prsa.planner_override_for(@student)).to eq override
    end
  end

  context "complete_for_planner scope" do
    before :once do
      course_with_student(active_all: true)
    end

    it "includes graded quiz with planner override marked complete" do
      assignment = assignment_model(course: @course, submission_types: "online_quiz", quiz: quiz_model(course: @course))
      quiz = assignment.quiz
      quiz.planner_overrides.create!(user: @student, marked_complete: true)

      expect(Assignment.published.complete_for_planner(@student)).to include(assignment)
    end

    it "includes graded discussion with planner override marked complete" do
      assignment = assignment_model(course: @course, submission_types: "discussion_topic")
      discussion = assignment.discussion_topic
      discussion.planner_overrides.create!(user: @student, marked_complete: true)

      expect(Assignment.published.complete_for_planner(@student)).to include(assignment)
    end

    it "includes wiki page assignment with planner override marked complete" do
      assignment = wiki_page_assignment_model(course: @course)
      wiki_page = assignment.wiki_page
      wiki_page.planner_overrides.create!(user: @student, marked_complete: true)

      expect(Assignment.published.complete_for_planner(@student)).to include(assignment)
    end

    it "includes regular assignment with planner override marked complete" do
      assignment = assignment_model(course: @course)
      assignment.planner_overrides.create!(user: @student, marked_complete: true)

      expect(Assignment.published.complete_for_planner(@student)).to include(assignment)
    end

    it "includes assignment with submission" do
      assignment = assignment_model(course: @course)
      assignment.submit_homework(@student, submission_type: "online_text_entry", body: "test")

      expect(Assignment.published.complete_for_planner(@student)).to include(assignment)
    end

    it "includes submitted graded discussion with no override" do
      assignment = assignment_model(course: @course, submission_types: "discussion_topic")
      assignment.submit_homework(@student, submission_type: "online_text_entry", body: "test")

      expect(Assignment.published.complete_for_planner(@student)).to include(assignment)
    end

    it "excludes submitted graded discussion marked incomplete" do
      assignment = assignment_model(course: @course, submission_types: "discussion_topic")
      assignment.submit_homework(@student, submission_type: "online_text_entry", body: "test")
      assignment.discussion_topic.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.complete_for_planner(@student)).not_to include(assignment)
    end

    it "excludes submitted graded quiz marked incomplete" do
      assignment = assignment_model(course: @course, submission_types: "online_quiz", quiz: quiz_model(course: @course))
      assignment.submit_homework(@student, submission_type: "online_quiz")
      assignment.quiz.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.complete_for_planner(@student)).not_to include(assignment)
    end
  end

  context "incomplete_for_planner scope" do
    before :once do
      course_with_student(active_all: true)
    end

    it "includes graded quiz without a planner override" do
      assignment = assignment_model(course: @course, submission_types: "online_quiz", quiz: quiz_model(course: @course))

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes quiz with planner override marked_complete: false" do
      assignment = assignment_model(course: @course, submission_types: "online_quiz", quiz: quiz_model(course: @course))
      assignment.quiz.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes graded discussion without a planner override" do
      assignment = assignment_model(course: @course, submission_types: "discussion_topic")

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes graded discussion with planner override marked_complete: false" do
      assignment = assignment_model(course: @course, submission_types: "discussion_topic")
      assignment.discussion_topic.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes wiki page assignment without a planner override" do
      assignment = wiki_page_assignment_model(course: @course)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes wiki page assignment with planner override marked_complete: false" do
      assignment = wiki_page_assignment_model(course: @course)
      assignment.wiki_page.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes submitted assignment with planner override marked_complete: false" do
      assignment = assignment_model(course: @course)
      assignment.submit_homework(@student, submission_type: "online_text_entry", body: "test")
      assignment.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes submitted assignment with redo_request" do
      assignment = assignment_model(course: @course)
      submission = assignment.submit_homework(@student, submission_type: "online_text_entry", body: "test")
      submission.update!(redo_request: true)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes submitted graded discussion marked incomplete" do
      assignment = assignment_model(course: @course, submission_types: "discussion_topic")
      assignment.submit_homework(@student, submission_type: "online_text_entry", body: "test")
      assignment.discussion_topic.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end

    it "includes submitted graded quiz marked incomplete" do
      assignment = assignment_model(course: @course, submission_types: "online_quiz", quiz: quiz_model(course: @course))
      assignment.submit_homework(@student, submission_type: "online_quiz")
      assignment.quiz.planner_overrides.create!(user: @student, marked_complete: false)

      expect(Assignment.published.incomplete_for_planner(@student)).to include(assignment)
    end
  end
end
