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
#

require_relative "../graphql_spec_helper"

describe Types::ModuleStatisticsType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end

  let_once(:module1) do
    @module = course.context_modules.create!(name: "Module 1")
  end

  let_once(:assignment1) do
    assignment = course.assignments.create!(title: "Assignment 1", workflow_state: "published", submission_types: ["online_text_entry"])
    module1.add_item(type: "assignment", id: assignment.id)
    assignment
  end

  let_once(:assignment2) do
    assignment = course.assignments.create!(title: "Assignment 2", workflow_state: "published", submission_types: ["online_text_entry"])
    module1.add_item(type: "assignment", id: assignment.id)
    assignment
  end

  let_once(:assignment3) do
    assignment = course.assignments.create!(title: "Assignment 3", workflow_state: "published", submission_types: ["online_text_entry"])
    module1.add_item(type: "assignment", id: assignment.id)
    assignment
  end

  let_once(:module_with_discussion_that_has_no_assignment) do
    course.context_modules.create!(name: "module_with_discussion_that_has_no_assignment")
  end

  let_once(:discussion_without_assignment) do
    discussion = course.discussion_topics.create!(message: "hi", title: "discussion title")
    module_with_discussion_that_has_no_assignment.add_item(type: "discussion_topic", id: discussion.id)
    discussion
  end

  let_once(:module_with_graded_discussion) do
    course.context_modules.create!(name: "module_with_graded_discussion")
  end

  let_once(:assignment_for_graded_discussion) do
    course.assignments.create!(title: "Assignment for graded discussion", workflow_state: "published", submission_types: ["online_text_entry"])
  end

  let_once(:graded_discussion) do
    discussion = course.discussion_topics.create!(message: "hi2", title: "discussion title2", assignment: assignment_for_graded_discussion)
    module_with_graded_discussion.add_item(type: "discussion_topic", id: discussion.id)
    discussion
  end

  let_once(:module_with_checkpoint_discussion) do
    course.context_modules.create!(name: "module_with_checkpoint_discussion")
  end

  let_once(:assignment_for_checkpoint_discussion) do
    parent_assignment = course.assignments.create!(has_sub_assignments: true, title: "Parent Assignment", workflow_state: "published")
    parent_assignment.sub_assignments.create!(
      context: course,
      sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
      title: "Sub Assignment 1",
      workflow_state: "published",
      submission_types: "discussion_topic"
    )
    parent_assignment
  end

  let_once(:checkpoint_discussion) do
    discussion = course.discussion_topics.create!(message: "hi2", title: "discussion title2", assignment: assignment_for_checkpoint_discussion)
    module_with_checkpoint_discussion.add_item(type: "discussion_topic", id: discussion.id)
    discussion
  end

  let_once(:module_with_quiz_that_has_no_assignment) do
    course.context_modules.create!(name: "module_with_quiz_that_has_no_assignment")
  end

  let_once(:classic_quiz_without_assignment) do
    quiz = course.quizzes.create!(title: "classic_quiz_without_assignment")
    module_with_quiz_that_has_no_assignment.add_item(type: "quiz", id: quiz.id)
    quiz
  end

  let_once(:module_with_classic_quiz_that_has_assignment) do
    course.context_modules.create!(name: "module_with_classic_quiz")
  end

  let_once(:assignment_for_classic_quiz) do
    course.assignments.create!(title: "Assignment for classic quiz", workflow_state: "published", submission_types: ["online_text_entry"])
  end

  let_once(:classic_quiz_with_assignment) do
    quiz = course.quizzes.create!(title: "classic_quiz_with_assignment", assignment: assignment_for_classic_quiz)
    module_with_classic_quiz_that_has_assignment.add_item(type: "quiz", id: quiz.id)
    quiz
  end

  let_once(:module_type) { GraphQLTypeTester.new(module1, current_user: @student) }

  let(:now) { Time.zone.now }

  describe "module submissionStatistics" do
    describe "latestDueAt" do
      it "returns the latest due date among all assignments in the module" do
        Timecop.freeze(now) do
          submission1 = assignment1.submissions.find_by(user_id: @student.id)
          submission1.update!(cached_due_date: now + 2.days)

          submission2 = assignment2.submissions.find_by(user_id: @student.id)
          submission2.update!(cached_due_date: now + 1.day)

          result = module_type.resolve("submissionStatistics { latestDueAt }")

          expect(Time.zone.parse(result)).to be_within(1.second).of(now + 2.days)
        end
      end

      it "returns nil when no assignments have due dates" do
        result = module_type.resolve("submissionStatistics { latestDueAt }")
        expect(result).to be_nil
      end

      context "when assignment is attached to discussions" do
        it "returns nil when a discussion has no assignment" do
          result = GraphQLTypeTester.new(module_with_discussion_that_has_no_assignment, current_user: @student)
                                    .resolve("submissionStatistics { latestDueAt }")
          expect(result).to be_nil
        end

        it "returns the latest due date if graded discussion with due at date" do
          Timecop.freeze(now) do
            submission = assignment_for_graded_discussion.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now + 2.days)

            result = GraphQLTypeTester.new(module_with_graded_discussion, current_user: @student)
                                      .resolve("submissionStatistics { latestDueAt }")

            expect(Time.zone.parse(result)).to be_within(1.second).of(now + 2.days)
          end
        end

        it "returns the latest due date if checkpoint discussion with due at date" do
          Timecop.freeze(now) do
            sub_assignments = assignment_for_checkpoint_discussion.sub_assignments
            submission = sub_assignments.first.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now + 2.days)

            result = GraphQLTypeTester.new(module_with_checkpoint_discussion, current_user: @student)
                                      .resolve("submissionStatistics { latestDueAt }")

            expect(Time.zone.parse(result)).to be_within(1.second).of(now + 2.days)
          end
        end
      end

      context "when assignment is attached to classic quiz" do
        it "returns nil when a quiz has no submission" do
          result = GraphQLTypeTester.new(module_with_quiz_that_has_no_assignment, current_user: @student)
                                    .resolve("submissionStatistics { latestDueAt }")
          expect(result).to be_nil
        end

        it "returns the latest due date if quiz has submission" do
          Timecop.freeze(now) do
            submission = assignment_for_classic_quiz.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now + 2.days)

            result = GraphQLTypeTester.new(module_with_classic_quiz_that_has_assignment, current_user: @student)
                                      .resolve("submissionStatistics { latestDueAt }")

            expect(Time.zone.parse(result)).to be_within(1.second).of(now + 2.days)
          end
        end
      end
    end

    describe "missingAssignmentCount" do
      it "returns the count of overdue assignments" do
        Timecop.freeze(now) do
          submission = assignment1.submissions.find_by(user_id: @student.id)
          submission.update!(cached_due_date: now - 1.day, late_policy_status: nil, grader_id: nil)

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")

          expect(result).to eq 1
        end
      end

      it "includes assignments marked as missing in the overdue count" do
        Timecop.freeze(now) do
          submission = assignment1.submissions.find_by(user_id: @student.id)
          submission.update!(cached_due_date: now - 1.day, late_policy_status: "missing")

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")

          expect(result).to eq 1
        end
      end

      it "returns zero when no assignments are overdue" do
        Timecop.freeze(now) do
          submission = assignment1.submissions.find_by(user_id: @student.id)
          submission.update!(cached_due_date: now + 1.day)

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")

          expect(result).to eq 0
        end
      end

      it "excludes unpublished assignments from the overdue count" do
        Timecop.freeze(now) do
          # Setup: One published and one unpublished assignment, both overdue
          assignment1.update!(workflow_state: "unpublished")
          submission1 = assignment1.submissions.find_by(user_id: @student.id)
          submission1.update!(cached_due_date: now - 1.day, late_policy_status: "missing")

          assignment2.update!(workflow_state: "published")
          submission2 = assignment2.submissions.find_by(user_id: @student.id)
          submission2.update!(cached_due_date: now - 1.day, late_policy_status: "missing")

          expect(assignment1.published?).to be false
          expect(assignment2.published?).to be true
          expect(submission1.missing?).to be true
          expect(submission2.missing?).to be true

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")
          expect(result).to eq 1
        end
      end

      context "when assignment is attached to discussions" do
        it "returns 0 missingAssignmentCount when a discussion has no submission" do
          result = GraphQLTypeTester.new(module_with_discussion_that_has_no_assignment, current_user: @student)
                                    .resolve("submissionStatistics { missingAssignmentCount }")

          expect(result).to eq 0
        end

        it "returns 1 missingAssignmentCount if discussion is graded and the submission is in missing state" do
          Timecop.freeze(now) do
            submission = assignment_for_graded_discussion.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now - 1.day)

            result = GraphQLTypeTester.new(module_with_graded_discussion, current_user: @student)
                                      .resolve("submissionStatistics { missingAssignmentCount }")

            expect(result).to eq 1
          end
        end

        it "returns 1 missingAssignmentCount if discussion is checkpoint and the submission is in missing state" do
          Timecop.freeze(now) do
            sub_assignments = assignment_for_checkpoint_discussion.sub_assignments
            submission = sub_assignments.first.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now - 1.day)

            result = GraphQLTypeTester.new(module_with_checkpoint_discussion, current_user: @student)
                                      .resolve("submissionStatistics { missingAssignmentCount }")

            expect(result).to eq 1
          end
        end
      end

      context "when assignment is attached to classic quiz" do
        it "returns 0 missingAssignmentCount when a quiz has no submission" do
          result = GraphQLTypeTester.new(module_with_quiz_that_has_no_assignment, current_user: @student)
                                    .resolve("submissionStatistics { missingAssignmentCount }")
          expect(result).to eq 0
        end

        it "returns 1 missingAssignmentCount if quiz has a submission in missing state" do
          Timecop.freeze(now) do
            submission = assignment_for_classic_quiz.submissions.find_by(user_id: @student.id)
            submission.update!(cached_due_date: now - 1.day)

            result = GraphQLTypeTester.new(module_with_classic_quiz_that_has_assignment, current_user: @student)
                                      .resolve("submissionStatistics { missingAssignmentCount }")

            expect(result).to eq 1
          end
        end
      end
    end
  end

  describe "edge cases" do
    it "returns zero overdue count when the module has no content tags" do
      empty_module = course.context_modules.create!(name: "Empty Module")
      module_type = GraphQLTypeTester.new(empty_module, current_user: @student)

      result = module_type.resolve("submissionStatistics { missingAssignmentCount }")
      expect(result).to eq 0
    end

    it "returns zero overdue count when no submissions are overdue" do
      new_student = user_factory(active_all: true)
      course.enroll_student(new_student, enrollment_state: "active")

      sub = assignment1.submissions.find_by(user_id: new_student.id)
      expect(sub).not_to be_nil
      expect(sub.cached_due_date).to be_nil
      expect(sub.missing?).to be false

      module_type = GraphQLTypeTester.new(module1, current_user: new_student)

      result = module_type.resolve("submissionStatistics { missingAssignmentCount }")
      expect(result).to eq 0
    end

    it "returns nil for latest_due_at when the module has no content tags" do
      empty_module = course.context_modules.create!(name: "Empty Module")
      module_type = GraphQLTypeTester.new(empty_module, current_user: @student)

      result = module_type.resolve("submissionStatistics { latestDueAt }")
      expect(result).to be_nil
    end

    it "returns nil for latest_due_at when no submissions have due dates" do
      assignment1.submissions.find_by(user_id: @student.id).update!(cached_due_date: nil)
      assignment2.submissions.find_by(user_id: @student.id).update!(cached_due_date: nil)
      assignment3.submissions.find_by(user_id: @student.id).update!(cached_due_date: nil)

      result = module_type.resolve("submissionStatistics { latestDueAt }")
      expect(result).to be_nil
    end

    it "returns missingAssignmentCount for a missing state submission that associated with 2 modules" do
      Timecop.freeze(now) do
        submission = assignment1.submissions.find_by(user_id: @student.id)
        submission.update!(cached_due_date: now - 1.day, late_policy_status: nil, grader_id: nil)
        module_with_assignment_1 = course.context_modules.create!(name: "module with assignment 1")
        module_with_assignment_1.add_item(type: "assignment", id: assignment1.id)
        module_with_assignment_2 = course.context_modules.create!(name: "module with assignment 2")
        module_with_assignment_2.add_item(type: "assignment", id: assignment1.id)

        GraphQL::Batch.batch do
          Loaders::ModuleStatisticsLoader.for(current_user: @student)
                                         .load_many([module_with_assignment_1, module_with_assignment_2])
                                         .then { |results| expect(results).to all(satisfy { |list| list.length == 1 }) }
        end
      end
    end

    it "should not use deleted content tags" do
      module_with_assignment_1 = course.context_modules.create!(name: "module with assignment 1")
      module_item = module_with_assignment_1.add_item(type: "assignment", id: assignment1.id)
      module_item.destroy!

      GraphQL::Batch.batch do
        Loaders::ModuleStatisticsLoader.for(current_user: @student)
                                       .load_many([module_with_assignment_1])
                                       .then { |results| expect(results.flatten).to be_empty }
      end
    end
  end
end
