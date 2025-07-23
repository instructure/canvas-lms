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

RSpec.describe Loaders::AssignmentExternalToolTagLoader do
  before :once do
    course_with_teacher(active_all: true)
    @assignment1 = @course.assignments.create!(title: "Assignment 1", points_possible: 10)
    @assignment2 = @course.assignments.create!(title: "Assignment 2", points_possible: 10)
    @assignment3 = @course.assignments.create!(title: "Assignment 3", points_possible: 10)

    @external_tool = @course.context_external_tools.create!(
      name: "Test Tool",
      url: "http://example.com/launch",
      consumer_key: "key",
      shared_secret: "secret"
    )
  end

  let(:loader) { Loaders::AssignmentExternalToolTagLoader.for }

  describe "#perform" do
    it "returns nil for assignments without external tool tags" do
      assignments = [@assignment1, @assignment2, @assignment3]

      GraphQL::Batch.batch do
        promises = assignments.map { |assignment| loader.load(assignment.id) }
        Promise.all(promises).then do |values|
          expect(values).to all(be_nil)
        end
      end
    end

    it "returns external tool tags for assignments that have them" do
      # Create external tool tags for assignment1 and assignment2
      tag1 = ContentTag.create!(
        context: @assignment1,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )

      tag2 = ContentTag.create!(
        context: @assignment2,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )

      assignments = [@assignment1, @assignment2, @assignment3]

      GraphQL::Batch.batch do
        promises = assignments.map { |assignment| loader.load(assignment.id) }
        Promise.all(promises).then do |values|
          expect(values[0]).to eq(tag1)    # assignment1 has external tool tag
          expect(values[1]).to eq(tag2)    # assignment2 has external tool tag
          expect(values[2]).to be_nil      # assignment3 has no external tool tag
        end
      end
    end

    it "ignores content tags without content_type" do
      # Create a content tag without content_type
      ContentTag.create!(
        context: @assignment1,
        content: nil,
        content_type: nil
      )

      GraphQL::Batch.batch do
        loader.load(@assignment1.id).then do |result|
          expect(result).to be_nil
        end
      end
    end

    it "prevents N+1 queries when checking multiple assignments" do
      assignments = [@assignment1, @assignment2, @assignment3]

      # Add external tool tag to one assignment
      ContentTag.create!(
        context: @assignment1,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )

      expect do
        GraphQL::Batch.batch do
          promises = assignments.map { |assignment| loader.load(assignment.id) }
          Promise.all(promises).then(&:itself)
        end
      end.to make_database_queries(count: 1, matching: /SELECT.*content_tags.*FROM.*content_tags/)
    end

    it "handles empty assignment array" do
      expect do
        GraphQL::Batch.batch do
          # No assignments to load
        end
      end.not_to raise_error
    end

    it "works with assignments from different courses" do
      other_course = course_factory(active_all: true)
      other_assignment = other_course.assignments.create!(title: "Other Assignment", points_possible: 5)
      other_tool = other_course.context_external_tools.create!(
        name: "Other Tool",
        url: "http://example.com/other",
        consumer_key: "other_key",
        shared_secret: "other_secret"
      )

      # Create external tool tags
      tag1 = ContentTag.create!(
        context: @assignment1,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )

      tag2 = ContentTag.create!(
        context: other_assignment,
        content: other_tool,
        content_type: "ContextExternalTool"
      )

      GraphQL::Batch.batch do
        promises = [
          loader.load(@assignment1.id),
          loader.load(@assignment2.id),
          loader.load(other_assignment.id)
        ]

        Promise.all(promises).then do |values|
          expect(values[0]).to eq(tag1)    # has external tool tag
          expect(values[1]).to be_nil      # no external tool tag
          expect(values[2]).to eq(tag2)    # has external tool tag
        end
      end
    end

    it "loads multiple content tags correctly" do
      # Create content tags for multiple assignments
      tag1 = ContentTag.create!(
        context: @assignment1,
        content: @external_tool,
        content_type: "ContextExternalTool"
      )

      # Create a different external tool for assignment2
      other_tool = @course.context_external_tools.create!(
        name: "Other Tool",
        url: "http://example.com/other",
        consumer_key: "other_key",
        shared_secret: "other_secret"
      )

      tag2 = ContentTag.create!(
        context: @assignment2,
        content: other_tool,
        content_type: "ContextExternalTool"
      )

      GraphQL::Batch.batch do
        promises = [
          loader.load(@assignment1.id),
          loader.load(@assignment2.id),
          loader.load(@assignment3.id)
        ]

        Promise.all(promises).then do |values|
          expect(values[0]).to eq(tag1)
          expect(values[1]).to eq(tag2)
          expect(values[2]).to be_nil
        end
      end
    end
  end
end
