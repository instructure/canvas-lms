#
# Copyright (C) 2018 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::HideAssignmentGrades do
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create!(workflow_state: "available") }
  let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
  let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

  def mutation_str(assignment_id: nil)
    input_string = assignment_id ? "assignmentId: #{assignment_id}" : ""

    <<~GQL
      mutation {
        hideAssignmentGrades(input: {
          #{input_string}
        }) {
          assignment {
            _id
          }
          progress {
            _id
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def execute_query(mutation_str, context)
    CanvasSchema.execute(mutation_str, context: context)
  end

  before(:each) do
    course.enable_feature!(:post_policies)
  end

  context "when user has grade permission" do
    let(:context) { { current_user: teacher } }

    it "requires that the PostPolicy feature be enabled" do
      course.disable_feature!(:post_policies)
      result = execute_query(mutation_str(assignment_id: assignment.id), context)
      expect(result.dig("errors", 0, "message")).to eql "Post Policies feature not enabled"
    end

    it "requires that assignmentId be passed in the query" do
      result = execute_query(mutation_str, context)
      expected_error = "'assignmentId' on InputObject 'HideAssignmentGradesInput' is required"
      expect(result.dig("errors", 0, "message")).to include expected_error
    end

    it "returns an error when the assignment does not exist" do
      bad_id = (Assignment.last&.id || 0) + 1
      result = execute_query(mutation_str(assignment_id: bad_id), context)
      expect(result.dig("errors", 0, "message")).to eql "not found"
    end

    it "returns an error when assignment is moderated and grades have yet to be published" do
      assignment.update!(moderated_grading: true, grader_count: 2, final_grader: teacher)
      result = execute_query(mutation_str(assignment_id: assignment.id), context)
      expected_error = "Assignments under moderation cannot be hidden before grades are published"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    it "does not return an error when assignment is moderated and grades have been published" do
      now = Time.zone.now
      assignment.update!(moderated_grading: true, grader_count: 2, final_grader: teacher, grades_published_at: now)
      result = execute_query(mutation_str(assignment_id: assignment.id), context)
      expect(result.dig("errors")).to be nil
    end

    describe "hiding the grades" do
      before(:each) do
        @student_submission = assignment.submissions.find_by(user: student)
        @student_submission.update!(posted_at: Time.zone.now)
      end

      it "hides the assignment grades" do
        execute_query(mutation_str(assignment_id: assignment.id), context)
        hide_submissions_job = Delayed::Job.where(tag: "Assignment#hide_submissions").order(:id).last
        hide_submissions_job.invoke_job
        expect(@student_submission.reload).not_to be_posted
      end

      it "returns the assignment" do
        result = execute_query(mutation_str(assignment_id: assignment.id), context)
        expect(result.dig("data", "hideAssignmentGrades", "assignment", "_id").to_i).to be assignment.id
      end

      it "returns the progress" do
        result = execute_query(mutation_str(assignment_id: assignment.id), context)
        progress = Progress.where(tag: "hide_assignment_grades").order(:id).last
        expect(result.dig("data", "hideAssignmentGrades", "progress", "_id").to_i).to be progress.id
      end
    end
  end

  context "when user does not have grade permission" do
    let(:context) { { current_user: student } }

    it "returns an error" do
      result = execute_query(mutation_str(assignment_id: assignment.id), context)
      expect(result.dig("errors", 0, "message")).to eql "not found"
    end

    it "does not return data for the related submissions" do
      result = execute_query(mutation_str(assignment_id: assignment.id), context)
      expect(result.dig("data", "hideAssignmentGrades")).to be nil
    end
  end
end
