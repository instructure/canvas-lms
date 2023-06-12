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

describe Mutations::SetCoursePostPolicy do
  let(:assignment) { course.assignments.create! }
  let(:course) { Course.create!(workflow_state: "available") }
  let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
  let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

  def mutation_str(course_id: nil, post_manually: nil)
    input_string = course_id ? "courseId: #{course_id}" : ""
    input_string += " postManually: #{post_manually}" if post_manually.present?

    <<~GQL
      mutation {
        setCoursePostPolicy(input: {
          #{input_string}
        }) {
          postPolicy {
            course {
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

    it "requires that courseId be passed in the query" do
      result = execute_query(mutation_str(post_manually: true), context)
      expected_error = "'courseId' on InputObject 'SetCoursePostPolicyInput' is required"
      expect(result.dig("errors", 0, "message")).to include expected_error
    end

    it "requires that postManually be passed in the query" do
      result = execute_query(mutation_str(course_id: course.id), context)
      expected_error = "'postManually' on InputObject 'SetCoursePostPolicyInput' is required"
      expect(result.dig("errors", 0, "message")).to include expected_error
    end

    it "returns an error if the provided course id does not exist" do
      bad_id = (Course.last&.id || 0) + 1
      result = execute_query(mutation_str(course_id: bad_id, post_manually: true), context)
      expected_error = "A course with that id does not exist"
      expect(result.dig("errors", 0, "message")).to eql expected_error
    end

    it "returns the related post policy" do
      result = execute_query(mutation_str(course_id: course.id, post_manually: true), context)
      policy = PostPolicy.find_by(course:, assignment: nil)
      expect(result.dig("data", "setCoursePostPolicy", "postPolicy", "_id").to_i).to be policy.id
    end

    describe "updating the post policy of assignments in the course" do
      let(:policy) { PostPolicy.create!(course:, post_manually: false) }
      let(:post_manually_mutation) { mutation_str(course_id: course.id, post_manually: true) }

      let(:assignment) { course.assignments.create! }
      let(:anonymous_assignment) { course.assignments.create!(anonymous_grading: true) }
      let(:moderated_assignment) do
        course.assignments.create!(
          final_grader: teacher,
          grader_count: 2,
          moderated_grading: true
        )
      end

      it "explicitly sets a post policy for assignments without one" do
        auto_assignment = course.assignments.create!
        execute_query(post_manually_mutation, context)
        expect(auto_assignment.reload.post_policy).to be_post_manually
      end

      it "updates the post policy for assignments with an existing-but-different policy" do
        assignment.ensure_post_policy(post_manually: false)

        execute_query(post_manually_mutation, context)
        expect(assignment.reload.post_policy).to be_post_manually
      end

      it "does not update assignments that have an equivalent post policy" do
        assignment.ensure_post_policy(post_manually: true)

        expect do
          execute_query(post_manually_mutation, context)
        end.not_to change {
          PostPolicy.find_by!(assignment:).updated_at
        }
      end

      it "does not update anonymous assignments" do
        expect do
          execute_query(post_manually_mutation, context)
        end.not_to change {
          PostPolicy.find_by!(assignment: anonymous_assignment).updated_at
        }
      end

      it "does not update moderated assignments" do
        expect do
          execute_query(post_manually_mutation, context)
        end.not_to change {
          PostPolicy.find_by!(assignment: moderated_assignment).updated_at
        }
      end
    end
  end

  context "when user does not have manage_grades permission" do
    let(:context) { { current_user: student } }

    it "returns an error" do
      result = execute_query(mutation_str(course_id: course.id, post_manually: true), context)
      expect(result.dig("errors", 0, "message")).to eql "not found"
    end

    it "does not return data for the related post policy" do
      result = execute_query(mutation_str(course_id: course.id, post_manually: true), context)
      expect(result.dig("data", "setCoursePostPolicy")).to be_nil
    end
  end
end
