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

describe Types::PeerReviewSubAssignmentType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:teacher) { teacher_in_course(active_all: true, course:).user }
  let_once(:student) { student_in_course(course:, active_all: true).user }

  before(:once) do
    course.enable_feature!(:peer_review_allocation_and_grading)
    @parent_assignment = course.assignments.create!(
      title: "Parent Assignment",
      peer_reviews: true,
      peer_review_count: 2,
      points_possible: 10
    )
    @peer_review_sub_assignment = peer_review_model(parent_assignment: @parent_assignment)
  end

  let(:peer_review_type) { GraphQLTypeTester.new(@peer_review_sub_assignment, current_user: teacher, request: ActionDispatch::TestRequest.create) }

  describe "inherited fields from AssignmentType" do
    it "resolves inherited fields" do
      expect(peer_review_type.resolve("_id")).to eq @peer_review_sub_assignment.id.to_s
      expect(peer_review_type.resolve("name")).to eq @peer_review_sub_assignment.name
      expect(peer_review_type.resolve("state")).to eq @peer_review_sub_assignment.workflow_state
      expect(peer_review_type.resolve("courseId")).to eq @peer_review_sub_assignment.context_id.to_s
      expect(peer_review_type.resolve("pointsPossible")).to eq @peer_review_sub_assignment.points_possible
    end

    it "overrides html_url to point to parent assignment" do
      url = peer_review_type.resolve("htmlUrl")
      expect(url).to include("/courses/#{course.id}/assignments/#{@parent_assignment.id}")
    end
  end

  describe "new fields" do
    it "returns parent assignment id" do
      expect(peer_review_type.resolve("parentAssignmentId")).to eq @parent_assignment.id.to_s
    end

    it "returns parent assignment object" do
      expect(peer_review_type.resolve("parentAssignment { _id }")).to eq @parent_assignment.id.to_s
    end
  end

  describe "permissions" do
    it "respects read permissions via assignment endpoint" do
      other_course = course_factory
      other_student = student_in_course(course: other_course, active_all: true).user

      query = <<~GQL
        query($id: ID!) {
          assignment(id: $id) {
            ... on PeerReviewSubAssignment {
              _id
            }
          }
        }
      GQL

      result = CanvasSchema.execute(
        query,
        variables: { id: @peer_review_sub_assignment.id.to_s },
        context: { current_user: other_student }
      )

      expect(result.dig("data", "assignment")).to be_nil
    end

    it "respects read permissions via peerReviewSubAssignment endpoint" do
      other_course = course_factory
      other_student = student_in_course(course: other_course, active_all: true).user

      query = <<~GQL
        query($id: ID!) {
          peerReviewSubAssignment(id: $id) {
            _id
          }
        }
      GQL

      result = CanvasSchema.execute(
        query,
        variables: { id: @peer_review_sub_assignment.id.to_s },
        context: { current_user: other_student }
      )

      expect(result.dig("data", "peerReviewSubAssignment")).to be_nil
    end
  end
end
