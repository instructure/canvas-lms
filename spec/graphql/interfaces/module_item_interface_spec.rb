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

require "spec_helper"

RSpec.describe Interfaces::ModuleItemInterface do
  before :once do
    course_with_teacher(active_all: true)
    @student = course_with_user("StudentEnrollment", course: @course, active_all: true).user
    @assignment1 = @course.assignments.create!(title: "Assignment 1", points_possible: 10)
    @assignment2 = @course.assignments.create!(title: "Assignment 2", points_possible: 10)

    @external_tool = @course.context_external_tools.create!(
      name: "Test Tool",
      url: "http://example.com/launch",
      consumer_key: "key",
      shared_secret: "secret"
    )
  end

  let(:context) { { current_user: @teacher, request: ActionDispatch::Request.new({}) } }

  describe "can_duplicate field" do
    let(:query) do
      <<~GQL
        query {
          course(id: "#{@course.id}") {
            assignmentsConnection {
              nodes {
                id
                canDuplicate
              }
            }
          }
        }
      GQL
    end

    it "returns true for regular assignments" do
      result = CanvasSchema.execute(query, context:)
      assignments = result.dig("data", "course", "assignmentsConnection", "nodes")

      assignment_results = assignments.select { |a| [CanvasSchema.id_from_object(@assignment1, Types::AssignmentType, context), CanvasSchema.id_from_object(@assignment2, Types::AssignmentType, context)].include?(a["id"]) }
      expect(assignment_results).to all(include("canDuplicate" => true))
    end

    it "returns false for external tool assignments" do
      # Setup assignment1 as external tool assignment
      ContentTag.create!(
        context: @assignment1,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )
      @assignment1.update!(submission_types: ["external_tool"])

      result = CanvasSchema.execute(query, context:)
      assignments = result.dig("data", "course", "assignmentsConnection", "nodes")

      assignment1_result = assignments.find { |a| a["id"] == CanvasSchema.id_from_object(@assignment1, Types::AssignmentType, context) }
      assignment2_result = assignments.find { |a| a["id"] == CanvasSchema.id_from_object(@assignment2, Types::AssignmentType, context) }

      expect(assignment1_result["canDuplicate"]).to be false
      expect(assignment2_result["canDuplicate"]).to be true
    end

    it "batches external tool tag loading to prevent N+1 queries" do
      # Create multiple assignments
      assignments = Array.new(5) { |i| @course.assignments.create!(title: "Assignment #{i + 3}", points_possible: 10) }

      # Add external tool to one assignment
      ContentTag.create!(
        context: assignments.first,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )

      expect do
        CanvasSchema.execute(query, context:)
      end.to make_database_queries(count: 1, matching: /SELECT.*content_tags.*FROM.*content_tags.*WHERE.*context_type.*=.*Assignment/)
    end
  end

  describe "can_manage_assign_to field" do
    let(:assignment_query) do
      <<~GQL
        query {
          course(id: "#{@course.id}") {
            assignmentsConnection {
              nodes {
                id
                canManageAssignTo
              }
            }
          }
        }
      GQL
    end

    let(:quiz_query) do
      <<~GQL
        query {
          course(id: "#{@course.id}") {
            quizzesConnection {
              nodes {
                id
                canManageAssignTo
              }
            }
          }
        }
      GQL
    end

    let(:discussion_query) do
      <<~GQL
        query {
          course(id: "#{@course.id}") {
            discussionsConnection {
              nodes {
                id
                canManageAssignTo
              }
            }
          }
        }
      GQL
    end

    let(:page_query) do
      <<~GQL
        query {
          course(id: "#{@course.id}") {
            pagesConnection {
              nodes {
                id
                canManageAssignTo
              }
            }
          }
        }
      GQL
    end

    it "returns true for differentiable types" do
      @course.quizzes.create!
      @course.wiki_pages.create!(title: "test page")
      @course.discussion_topics.create!

      assignments = CanvasSchema.execute(assignment_query, context:).dig("data", "course", "assignmentsConnection", "nodes")
      quizzes = CanvasSchema.execute(quiz_query, context:).dig("data", "course", "quizzesConnection", "nodes")
      discussions = CanvasSchema.execute(discussion_query, context:).dig("data", "course", "discussionsConnection", "nodes")
      pages = CanvasSchema.execute(page_query, context:).dig("data", "course", "pagesConnection", "nodes")

      assignments.each do |assignment|
        expect(assignment["canManageAssignTo"]).to be true
      end
      quizzes.each do |quiz|
        expect(quiz["canManageAssignTo"]).to be true
      end
      discussions.each do |discussion|
        expect(discussion["canManageAssignTo"]).to be true
      end
      pages.each do |page|
        expect(page["canManageAssignTo"]).to be true
      end
    end

    it "returns false for ungraded group discussions" do
      group = @course.group_categories.create!(name: "Ungraded Group Category")
      ungraded_discussion = @course.discussion_topics.create!(title: "Ungraded Discussion", group_category_id: nil)
      ungraded_group_discussion = @course.discussion_topics.create!(title: "Ungraded Group Discussion", group_category_id: group.id)
      result = CanvasSchema.execute(discussion_query, context:)
      discussions = result.dig("data", "course", "discussionsConnection", "nodes")

      ungraded_group_discussion_result = discussions.find { |d| d["id"] == CanvasSchema.id_from_object(ungraded_group_discussion, Types::DiscussionType, context) }
      expect(ungraded_group_discussion_result["canManageAssignTo"]).to be false
      ungraded_discussion_result = discussions.find { |d| d["id"] == CanvasSchema.id_from_object(ungraded_discussion, Types::DiscussionType, context) }
      expect(ungraded_discussion_result["canManageAssignTo"]).to be true
    end
  end

  describe "can_unpublish field" do
    let(:query) do
      <<~GQL
        query {
          course(id: "#{@course.id}") {
            assignmentsConnection {
              nodes {
                id
                canUnpublish
              }
            }
          }
        }
      GQL
    end

    it "returns false for assignments with submissions" do
      # Add submission to assignment1
      @assignment1.submit_homework(@student, body: "test submission")

      result = CanvasSchema.execute(query, context:)
      assignments = result.dig("data", "course", "assignmentsConnection", "nodes")

      assignment1_result = assignments.find { |a| a["id"] == CanvasSchema.id_from_object(@assignment1, Types::AssignmentType, context) }
      assignment2_result = assignments.find { |a| a["id"] == CanvasSchema.id_from_object(@assignment2, Types::AssignmentType, context) }

      expect(assignment1_result["canUnpublish"]).to be false
      expect(assignment2_result["canUnpublish"]).to be true
    end

    it "returns true for assignments without submissions" do
      result = CanvasSchema.execute(query, context:)
      assignments = result.dig("data", "course", "assignmentsConnection", "nodes")

      assignment_results = assignments.select { |a| [CanvasSchema.id_from_object(@assignment1, Types::AssignmentType, context), CanvasSchema.id_from_object(@assignment2, Types::AssignmentType, context)].include?(a["id"]) }
      expect(assignment_results).to all(include("canUnpublish" => true))
    end

    it "batches submission existence loading to prevent N+1 queries" do
      # Create multiple assignments
      assignments = Array.new(5) { |i| @course.assignments.create!(title: "Assignment #{i + 3}", points_possible: 10) }

      # Add submission to one assignment
      assignments.first.submit_homework(@student, body: "test submission")

      expect do
        CanvasSchema.execute(query, context:)
      end.to make_database_queries(count: 1, matching: /SELECT.*assignment_id.*FROM.*submissions.*WHERE.*submissions\.workflow_state/)
    end
  end

  describe "has_submitted_submissions field" do
    let(:query) do
      <<~GQL
        query {
          course(id: "#{@course.id}") {
            assignmentsConnection {
              nodes {
                id
                hasSubmittedSubmissions
              }
            }
          }
        }
      GQL
    end

    it "returns correct values based on submission status" do
      # Add submission to assignment1
      @assignment1.submit_homework(@student, body: "test submission")

      result = CanvasSchema.execute(query, context:)
      assignments = result.dig("data", "course", "assignmentsConnection", "nodes")

      assignment1_result = assignments.find { |a| a["id"] == CanvasSchema.id_from_object(@assignment1, Types::AssignmentType, context) }
      assignment2_result = assignments.find { |a| a["id"] == CanvasSchema.id_from_object(@assignment2, Types::AssignmentType, context) }

      expect(assignment1_result["hasSubmittedSubmissions"]).to be true
      expect(assignment2_result["hasSubmittedSubmissions"]).to be false
    end

    it "batches submission existence loading to prevent N+1 queries" do
      # Create multiple assignments
      assignments = Array.new(5) { |i| @course.assignments.create!(title: "Assignment #{i + 3}", points_possible: 10) }

      # Add submission to one assignment
      assignments.first.submit_homework(@student, body: "test submission")

      expect do
        CanvasSchema.execute(query, context:)
      end.to make_database_queries(count: 1, matching: /SELECT.*assignment_id.*FROM.*submissions.*WHERE.*submissions\.workflow_state/)
    end
  end

  describe "combined query efficiency" do
    it "efficiently handles queries that use both can_duplicate and can_unpublish" do
      combined_query = <<~GQL
        query {
          course(id: "#{@course.id}") {
            assignmentsConnection {
              nodes {
                id
                canDuplicate
                canUnpublish
                hasSubmittedSubmissions
              }
            }
          }
        }
      GQL

      # Create additional assignments to test batching
      assignments = Array.new(3) { |i| @course.assignments.create!(title: "Assignment #{i + 3}", points_possible: 10) }

      # Add external tool tag to one assignment and set submission type
      ContentTag.create!(
        context: assignments.first,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )
      assignments.first.update!(submission_types: ["external_tool"])

      # Add submission to another assignment
      assignments.second.submit_homework(@student, body: "test submission")

      # Just verify that the query executes without errors and we get results
      result = CanvasSchema.execute(combined_query, context:)
      assignments_data = result.dig("data", "course", "assignmentsConnection", "nodes")
      expect(assignments_data.length).to be > 0

      # Check that the fields have the expected values
      assignment_with_tag = assignments_data.find { |a| a["canDuplicate"] == false }
      assignment_with_submission = assignments_data.find { |a| a["hasSubmittedSubmissions"] == true }

      expect(assignment_with_tag).not_to be_nil, "Should have an assignment with canDuplicate=false"
      expect(assignment_with_submission).not_to be_nil, "Should have an assignment with hasSubmittedSubmissions=true"
    end
  end
end
