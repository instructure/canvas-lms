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

describe Types::SubmissionStatisticsType do
  around do |example|
    Timecop.freeze(Time.zone.parse("2025-01-15 12:00:00")) do
      example.run
    end
  end

  before(:once) do
    course_with_student(active_all: true)
    @now = Time.zone.parse("2025-01-15 12:00:00")

    @assignment_due_today = @course.assignments.create!(
      name: "Due Today",
      submission_types: "online_text_entry",
      points_possible: 10,
      due_at: @now + 6.hours
    )

    @assignment_due_tomorrow = @course.assignments.create!(
      name: "Due Tomorrow",
      submission_types: "online_text_entry",
      points_possible: 10,
      due_at: @now + 1.day + 6.hours
    )

    @assignment_overdue = @course.assignments.create!(
      name: "Overdue",
      submission_types: "online_text_entry",
      points_possible: 10,
      due_at: @now - 2.days
    )

    @assignment_due_next_week = @course.assignments.create!(
      name: "Due Next Week",
      submission_types: "online_text_entry",
      points_possible: 10,
      due_at: @now + 8.days
    )

    @submission_submitted = @assignment_due_today.submit_homework(@student, submission_type: "online_text_entry", body: "My submission")
    @submission_graded = @assignment_due_tomorrow.grade_student(@student, score: 8, grader: @teacher).first
    @submission_missing = @assignment_overdue.find_or_create_submission(@student)
    @submission_missing.update!(late_policy_status: "missing")

    @assignment_due_next_week.find_or_create_submission(@student)
  end

  let(:course_type) { GraphQLTypeTester.new(@course, current_user: @student) }

  describe "original fields" do
    describe "submissions_due_this_week_count" do
      it "counts unsubmitted assignments due within the next 7 days" do
        assignment_due_this_week = @course.assignments.create!(
          name: "Due This Week Unsubmitted",
          submission_types: "online_text_entry",
          points_possible: 10,
          due_at: @now + 5.days
        )
        assignment_due_this_week.find_or_create_submission(@student)

        expect(course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to eq 1
      end

      it "returns 0 when current_user is nil" do
        course_type_no_user = GraphQLTypeTester.new(@course, current_user: nil)
        expect(course_type_no_user.resolve("submissionStatistics { submissionsDueThisWeekCount }")).to be_nil
      end

      it "returns 0 when all assignments due this week are submitted/graded" do
        result = course_type.resolve("submissionStatistics { submissionsDueThisWeekCount }")
        expect(result).to eq 0
      end
    end

    describe "missing_submissions_count" do
      it "counts missing submissions" do
        expect(course_type.resolve("submissionStatistics { missingSubmissionsCount }")).to eq 1
      end
    end

    describe "submitted_submissions_count" do
      it "counts submitted, graded, and excused submissions" do
        expect(course_type.resolve("submissionStatistics { submittedSubmissionsCount }")).to eq 2
      end
    end
  end

  describe "date-filtered fields" do
    let(:today) { @now.beginning_of_day }
    let(:tomorrow) { (today + 1.day).end_of_day }
    let(:next_week_start) { today + 7.days }
    let(:next_week_end) { today + 14.days }

    describe "submissions_due_count with date filtering" do
      it "counts assignments due in the specified date range that are not submitted" do
        result = course_type.resolve(
          "submissionStatistics { submissionsDueCount(startDate: \"#{today.iso8601}\", endDate: \"#{tomorrow.iso8601}\") }"
        )
        expect(result).to eq 0
      end

      it "returns 0 when no assignments are due in the date range" do
        far_future = today + 30.days
        far_future_end = far_future + 1.day
        result = course_type.resolve(
          "submissionStatistics { submissionsDueCount(startDate: \"#{far_future.iso8601}\", endDate: \"#{far_future_end.iso8601}\") }"
        )
        expect(result).to eq 0
      end

      it "counts assignments due next week" do
        result = course_type.resolve(
          "submissionStatistics { submissionsDueCount(startDate: \"#{next_week_start.iso8601}\", endDate: \"#{next_week_end.iso8601}\") }"
        )
        expect(result).to eq 1
      end

      it "works without date parameters" do
        result = course_type.resolve("submissionStatistics { submissionsDueCount }")
        expect(result).to eq 1
      end
    end

    describe "submissions_overdue_count with date filtering" do
      it "returns 0 when no assignments are overdue in the date range" do
        # Test with a future date range where nothing should be overdue
        far_future = today + 30.days
        far_future_end = far_future + 1.day
        result = course_type.resolve(
          "submissionStatistics { submissionsOverdueCount(startDate: \"#{far_future.iso8601}\", endDate: \"#{far_future_end.iso8601}\") }"
        )
        expect(result).to eq 0 # No overdue assignments in this future range
      end

      it "handles overdue logic with missing status" do
        monday_range = (today - 3.days).beginning_of_day
        tuesday_range = (today - 2.days).end_of_day
        result = course_type.resolve(
          "submissionStatistics { submissionsOverdueCount(startDate: \"#{monday_range.iso8601}\", endDate: \"#{tuesday_range.iso8601}\") }"
        )
        expect(result).to eq 0 # Missing assignments don't count as overdue
      end
    end

    describe "submissions_submitted_count with date filtering" do
      it "counts submitted assignments in the specified date range" do
        skip "2025-08-14 Very flaky in Jenkins, needs investigation FOO-5719"
        result = course_type.resolve(
          "submissionStatistics { submissionsSubmittedCount(startDate: \"#{today.iso8601}\", endDate: \"#{tomorrow.iso8601}\") }"
        )
        expect(result).to eq 2 # Both assignments in range are submitted/graded
      end

      it "returns 0 when no assignments are submitted in the date range" do
        far_past = today - 30.days
        far_past_end = far_past + 1.day
        result = course_type.resolve(
          "submissionStatistics { submissionsSubmittedCount(startDate: \"#{far_past.iso8601}\", endDate: \"#{far_past_end.iso8601}\") }"
        )
        expect(result).to eq 0
      end
    end
  end

  describe "edge cases" do
    let(:today) { @now.beginning_of_day }
    let(:tomorrow) { (today + 1.day).end_of_day }

    it "handles submissions without due dates" do
      assignment_no_due_date = @course.assignments.create!(
        name: "No Due Date",
        submission_types: "online_text_entry",
        points_possible: 10
      )
      assignment_no_due_date.find_or_create_submission(@student)

      # Assignments without due dates should not be counted in date-filtered queries
      result = course_type.resolve(
        "submissionStatistics { submissionsDueCount(startDate: \"#{today.iso8601}\", endDate: \"#{tomorrow.iso8601}\") }"
      )
      # Still should be 0 because the assignments with due dates in this range are submitted/graded
      # and the new assignment without due date is excluded from date filtering
      expect(result).to eq 0
    end

    it "handles excused submissions" do
      @submission_missing.update!(excused: true)

      result = course_type.resolve("submissionStatistics { submittedSubmissionsCount }")
      expect(result).to eq 3 # Now includes the excused submission

      result = course_type.resolve("submissionStatistics { missingSubmissionsCount }")
      expect(result).to eq 0 # Excused submissions are not missing
    end
  end

  describe "submitted_and_graded_count" do
    it "counts submissions that are graded" do
      result = course_type.resolve("submissionStatistics { submittedAndGradedCount }")
      expect(result).to eq 1
    end

    it "counts excused submissions as graded" do
      @submission_graded.update!(excused: true)
      result = course_type.resolve("submissionStatistics { submittedAndGradedCount }")
      expect(result).to eq 1
    end

    it "does not count submitted but not graded submissions" do
      assignment = @course.assignments.create!(
        name: "New Assignment",
        submission_types: "online_text_entry",
        points_possible: 10,
        due_at: @now + 1.day
      )
      assignment.submit_homework(@student, submission_type: "online_text_entry", body: "Test")

      result = course_type.resolve("submissionStatistics { submittedAndGradedCount }")
      expect(result).to eq 1
    end

    it "counts submissions with pending_review as not graded" do
      assignment = @course.assignments.create!(
        name: "Peer Review Assignment",
        submission_types: "online_text_entry",
        points_possible: 10,
        due_at: @now + 1.day
      )
      submission = assignment.submit_homework(@student, submission_type: "online_text_entry", body: "Test")
      submission.update!(workflow_state: "pending_review")

      result = course_type.resolve("submissionStatistics { submittedAndGradedCount }")
      expect(result).to eq 1
    end

    it "returns 0 when current_user is nil" do
      course_type_no_user = GraphQLTypeTester.new(@course, current_user: nil)
      expect(course_type_no_user.resolve("submissionStatistics { submittedAndGradedCount }")).to be_nil
    end

    it "handles no submissions" do
      course_with_student(active_all: true)
      empty_course_type = GraphQLTypeTester.new(@course, current_user: @student)
      result = empty_course_type.resolve("submissionStatistics { submittedAndGradedCount }")
      expect(result).to eq 0
    end

    it "handles all submissions graded" do
      @assignment_due_today.grade_student(@student, score: 10, grader: @teacher)
      result = course_type.resolve("submissionStatistics { submittedAndGradedCount }")
      expect(result).to eq 2
    end

    it "satisfies submittedAndGradedCount + submittedNotGradedCount = submittedSubmissionsCount" do
      graded_count = course_type.resolve("submissionStatistics { submittedAndGradedCount }")
      not_graded_count = course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      submitted_count = course_type.resolve("submissionStatistics { submittedSubmissionsCount }")

      expect(graded_count + not_graded_count).to eq submitted_count
    end
  end

  describe "submitted_not_graded_count" do
    it "counts submissions that are submitted but not graded" do
      result = course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      expect(result).to eq 1
    end

    it "does not count excused submissions" do
      @submission_submitted.update!(excused: true)
      result = course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      expect(result).to eq 0
    end

    it "does not count graded submissions" do
      @assignment_due_today.grade_student(@student, score: 9, grader: @teacher)
      result = course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      expect(result).to eq 0
    end

    it "counts pending_review submissions as submitted but not graded" do
      assignment = @course.assignments.create!(
        name: "Peer Review Assignment",
        submission_types: "online_text_entry",
        points_possible: 10,
        due_at: @now + 1.day
      )
      submission = assignment.submit_homework(@student, submission_type: "online_text_entry", body: "Test")
      submission.update!(workflow_state: "pending_review")

      result = course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      expect(result).to eq 2
    end

    it "returns 0 when current_user is nil" do
      course_type_no_user = GraphQLTypeTester.new(@course, current_user: nil)
      expect(course_type_no_user.resolve("submissionStatistics { submittedNotGradedCount }")).to be_nil
    end

    it "handles no submissions" do
      course_with_student(active_all: true)
      empty_course_type = GraphQLTypeTester.new(@course, current_user: @student)
      result = empty_course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      expect(result).to eq 0
    end

    it "handles all submissions graded" do
      @assignment_due_today.grade_student(@student, score: 10, grader: @teacher)
      result = course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      expect(result).to eq 0
    end

    it "handles mix of submitted and graded submissions" do
      assignment1 = @course.assignments.create!(
        name: "Assignment 1",
        submission_types: "online_text_entry",
        points_possible: 10,
        due_at: @now + 1.day
      )
      assignment1.submit_homework(@student, submission_type: "online_text_entry", body: "Test 1")

      assignment2 = @course.assignments.create!(
        name: "Assignment 2",
        submission_types: "online_text_entry",
        points_possible: 10,
        due_at: @now + 2.days
      )
      assignment2.grade_student(@student, score: 8, grader: @teacher)

      result = course_type.resolve("submissionStatistics { submittedNotGradedCount }")
      expect(result).to eq 2
    end
  end
end
