# frozen_string_literal: true

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

describe Mutations::SetAssignmentPostPolicy do
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create!(workflow_state: "available") }
  let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
  let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

  def mutation_str(assignment_id: nil, post_manually: nil)
    input_string = assignment_id ? "assignmentId: #{assignment_id}" : ""
    input_string += " postManually: #{post_manually} " unless post_manually.nil?

    <<~GQL
      mutation {
        setAssignmentPostPolicy(input: {
          #{input_string}
        }) {
          postPolicy {
            course {
              _id
            }
            assignment {
              _id
            }
            _id
            postManually
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
    CanvasSchema.execute(mutation_str, context:)
  end

  context "when user has manage_grades permission" do
    let(:context) { { current_user: teacher } }

    it "requires that assignmentId be passed in the query" do
      result = execute_query(mutation_str(post_manually: true), context)
      expected_error = "'assignmentId' on InputObject 'SetAssignmentPostPolicyInput' is required"
      expect(result.dig("errors", 0, "message")).to include expected_error
    end

    it "requires that postManually be passed in the query" do
      result = execute_query(mutation_str(assignment_id: assignment.id), context)
      expected_error = "'postManually' on InputObject 'SetAssignmentPostPolicyInput' is required"
      expect(result.dig("errors", 0, "message")).to include expected_error
    end

    it "returns an error if the provided assignment id does not exist" do
      bad_id = (Assignment.last&.id || 0) + 1
      result = execute_query(mutation_str(assignment_id: bad_id, post_manually: true), context)
      expected_error = "An assignment with that id does not exist"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    it "raises an error on setting an anonymous assignment to automatic posting" do
      assignment.update!(anonymous_grading: true)
      result = execute_query(mutation_str(assignment_id: assignment.id, post_manually: false), context)
      expected_error = "Anonymous assignments must be manually posted"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    context "for a moderated, non-anonymous assignment" do
      let(:moderated_assignment) do
        course.assignments.create!(moderated_grading: true, final_grader: teacher, grader_count: 2)
      end

      it "raises an error when setting an automatic post policy before grades are published" do
        result = execute_query(mutation_str(assignment_id: moderated_assignment.id, post_manually: false), context)
        expected_error = "Moderated assignments must be manually posted until grades are released"
        expect(result.dig("errors", 0, "message")).to eql expected_error
      end

      it "allows setting an automatic post policy when grades have been published" do
        moderated_assignment.update!(grades_published_at: Time.zone.now)
        result = execute_query(mutation_str(assignment_id: moderated_assignment.id, post_manually: false), context)
        expect(result.dig("data", "setAssignmentPostPolicy")).to have_key("postPolicy")
      end
    end

    it "returns the related post policy" do
      result = execute_query(mutation_str(assignment_id: assignment.id, post_manually: true), context)
      policy = PostPolicy.find_by(course:, assignment:)
      expect(result.dig("data", "setAssignmentPostPolicy", "postPolicy", "_id").to_i).to be policy.id
    end

    it "updates an existing assignment post policy when one exists" do
      result = execute_query(mutation_str(assignment_id: assignment.id, post_manually: true), context)
      expect(result.dig("data", "setAssignmentPostPolicy", "postPolicy", "_id").to_i).to be assignment.post_policy.id
    end
  end

  context "when user does not have manage_grades permission" do
    let(:context) { { current_user: student } }

    it "returns an error" do
      result = execute_query(mutation_str(assignment_id: assignment.id, post_manually: true), context)
      expect(result.dig("errors", 0, "message")).to eql "not found"
    end

    it "does not return data for the related post policy" do
      result = execute_query(mutation_str(assignment_id: assignment.id, post_manually: true), context)
      expect(result.dig("data", "setAssignmentPostPolicy")).to be_nil
    end
  end
end
