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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::ReorderModuleItems do
  let(:course) { Course.create! }
  let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }

  let(:module1) { course.context_modules.create!(name: "Module 1") }
  let(:module2) { course.context_modules.create!(name: "Module 2") }

  let(:assignment1) { course.assignments.create!(title: "Assignment 1") }
  let(:assignment2) { course.assignments.create!(title: "Assignment 2") }
  let(:assignment3) { course.assignments.create!(title: "Assignment 3") }

  let!(:item1) { module1.add_item(id: assignment1.id, type: "assignment") }
  let!(:item2) { module1.add_item(id: assignment2.id, type: "assignment") }
  let!(:item3) { module1.add_item(id: assignment3.id, type: "assignment") }

  def mutation_str(course_id: course.id, module_id: module1.id, item_ids: [item1.id, item2.id, item3.id], old_module_id: nil, target_position: nil)
    item_ids_str = item_ids.map { |id| "\"#{id}\"" }.join(", ")
    old_module_str = old_module_id ? "oldModuleId: \"#{old_module_id}\"" : ""
    target_position_str = target_position ? "targetPosition: #{target_position}" : ""

    <<~GQL
      mutation {
        reorderModuleItems(input: {
          courseId: "#{course_id}"
          moduleId: "#{module_id}"
          itemIds: [#{item_ids_str}]
          #{old_module_str}
          #{target_position_str}
        }) {
          module {
            _id
            name
            moduleItems {
              _id
              position
            }
          }
          oldModule {
            _id
            name
            moduleItems {
              _id
              position
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  before do
    course.offer!
  end

  context "when executed by a teacher with permission" do
    let(:context) { { current_user: teacher } }

    describe "same-module reordering" do
      it "reorders items within the same module" do
        # Original order: item1, item2, item3
        # New order: item3, item1, item2
        reordered_ids = [item3.id, item1.id, item2.id]

        result = CanvasSchema.execute(mutation_str(item_ids: reordered_ids), context:)

        expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil
        expect(result.dig("data", "reorderModuleItems", "module", "_id")).to eq module1.id.to_s

        # Verify positions in returned data
        module_items = result.dig("data", "reorderModuleItems", "module", "moduleItems")
        expect(module_items.length).to eq 3

        # Verify database positions
        module1.reload
        ordered_items = module1.content_tags.ordered
        expect(ordered_items.map(&:id)).to eq reordered_ids
        expect(ordered_items.map(&:position)).to eq [1, 2, 3]
      end

      it "handles partial reordering" do
        # Reorder just the first two items: item2, item1, item3
        reordered_ids = [item2.id, item1.id]

        result = CanvasSchema.execute(mutation_str(item_ids: reordered_ids), context:)

        expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil

        # Verify the reordered items are in correct positions
        module1.reload
        ordered_items = module1.content_tags.ordered
        expect(ordered_items.first(2).map(&:id)).to eq [item2.id, item1.id]
      end

      it "assigns unique sequential positions to all items after partial reordering" do
        # Initial state: item1(pos=1), item2(pos=2), item3(pos=3)
        module1.reload
        expect(module1.content_tags.ordered.map(&:position)).to eq [1, 2, 3]

        # Reorder just items [item3, item1] - this should put item3 first, item1 second
        reordered_ids = [item3.id, item1.id]

        result = CanvasSchema.execute(mutation_str(item_ids: reordered_ids), context:)
        expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil

        # After reordering, ALL items should have unique, sequential positions
        module1.reload
        all_items = module1.content_tags.ordered
        positions = all_items.map(&:position)

        # Verify all positions are unique and sequential
        expect(positions).to eq(positions.uniq), "Found duplicate positions: #{positions}"
        expect(positions).to eq((1..positions.length).to_a), "Expected sequential positions but got: #{positions}"

        # Expected final order: item3(1), item1(2), item2(3)
        expected_order = [item3.id, item1.id, item2.id]
        actual_order = all_items.map(&:id)
        expect(actual_order).to eq(expected_order)
      end

      it "handles single item reordering without creating duplicate position 1" do
        # Initial state: item1(pos=1), item2(pos=2), item3(pos=3)
        module1.reload
        expect(module1.content_tags.ordered.map(&:position)).to eq [1, 2, 3]

        # Reorder just item3 (should move it to first position)
        reordered_ids = [item3.id]

        result = CanvasSchema.execute(mutation_str(item_ids: reordered_ids), context:)
        expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil

        # After reordering, ALL items should have unique positions
        module1.reload
        all_items = module1.content_tags.ordered
        positions = all_items.map(&:position)

        # Should not have multiple items with position 1
        expect(positions).to eq(positions.uniq), "Found duplicate positions: #{positions}"
        expect(positions).to eq((1..positions.length).to_a), "Expected sequential positions but got: #{positions}"

        # Expected final order: item3(1), item1(2), item2(3)
        expected_order = [item3.id, item1.id, item2.id]
        actual_order = all_items.map(&:id)
        expect(actual_order).to eq(expected_order)
      end
    end

    describe "cross-module transfers" do
      before do
        # Add some items to module2 as well
        @module2_item1 = module2.add_item(id: course.assignments.create!(title: "Module 2 Assignment 1").id, type: "assignment")
      end

      it "moves items from one module to another" do
        # Move item1 and item2 from module1 to module2
        transfer_ids = [item1.id, item2.id]

        result = CanvasSchema.execute(
          mutation_str(
            module_id: module2.id,
            item_ids: transfer_ids,
            old_module_id: module1.id
          ),
          context:
        )

        expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil

        # Verify items moved to module2
        module2.reload
        expect(module2.content_tags.pluck(:id)).to include(item1.id, item2.id)

        # Verify items removed from module1
        module1.reload
        expect(module1.content_tags.pluck(:id)).not_to include(item1.id, item2.id)
        expect(module1.content_tags.pluck(:id)).to include(item3.id)

        # Verify positions are updated correctly
        expect(module2.content_tags.ordered.first(2).map(&:id)).to eq transfer_ids
      end

      it "returns both old and new modules" do
        result = CanvasSchema.execute(
          mutation_str(
            module_id: module2.id,
            item_ids: [item1.id],
            old_module_id: module1.id
          ),
          context:
        )

        expect(result.dig("data", "reorderModuleItems", "module", "_id")).to eq module2.id.to_s
        expect(result.dig("data", "reorderModuleItems", "oldModule", "_id")).to eq module1.id.to_s
      end

      it "accepts target_position parameter" do
        # Move item1 from module1 to module2 with target_position = 2
        result = CanvasSchema.execute(
          mutation_str(
            module_id: module2.id,
            item_ids: [item1.id],
            old_module_id: module1.id,
            target_position: 2
          ),
          context:
        )

        # Verify mutation succeeds
        expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil
        expect(result.dig("data", "reorderModuleItems", "module")).not_to be_nil

        # Verify item1 is moved to module2
        module2.reload
        expect(module2.content_tags.where(content_id: item1.content_id, content_type: item1.content_type).exists?).to be true

        # Verify item1 is removed from module1
        module1.reload
        expect(module1.content_tags.pluck(:id)).not_to include(item1.id)
      end
    end

    describe "validation and error handling" do
      it "returns error for non-existent course" do
        result = CanvasSchema.execute(mutation_str(course_id: 0), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "returns error for non-existent module" do
        result = CanvasSchema.execute(mutation_str(module_id: 0), context:)
        expect(result.dig("errors", 0, "message")).to eq "not found"
      end

      it "returns error for non-existent items" do
        result = CanvasSchema.execute(mutation_str(item_ids: [0, 999]), context:)
        expect(result.dig("data", "reorderModuleItems", "errors", 0, "message")).to eq "One or more items not found"
      end

      it "returns error when items don't belong to source module" do
        other_course = Course.create!
        other_module = other_course.context_modules.create!(name: "Other Module")
        other_item = other_module.add_item(id: other_course.assignments.create!(title: "Other Assignment").id, type: "assignment")

        result = CanvasSchema.execute(mutation_str(item_ids: [other_item.id]), context:)
        expect(result.dig("data", "reorderModuleItems", "errors", 0, "message")).to eq "One or more items not found"
      end

      it "returns error when trying to move items that don't belong to old_module" do
        # Try to move item1 from module2 (but it's actually in module1)
        result = CanvasSchema.execute(
          mutation_str(
            module_id: module2.id,
            item_ids: [item1.id],
            old_module_id: module2.id
          ),
          context:
        )

        expect(result.dig("data", "reorderModuleItems", "errors", 0, "message")).to eq "Items do not belong to source module"
      end

      it "handles empty item list gracefully" do
        result = CanvasSchema.execute(mutation_str(item_ids: []), context:)
        expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil
      end
    end
  end

  context "when executed by a student without permission" do
    let(:context) { { current_user: student } }

    it "returns authorization error" do
      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end

    it "does not return module data" do
      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("data", "reorderModuleItems")).to be_nil
    end
  end

  context "when executed without authentication" do
    it "returns authorization error" do
      result = CanvasSchema.execute(mutation_str, context: {})
      expect(result.dig("errors", 0, "message")).to eq "not found"
    end
  end

  describe "data integrity" do
    let(:context) { { current_user: teacher } }

    it "maintains position sequence integrity" do
      # Reorder items
      reordered_ids = [item2.id, item3.id, item1.id]
      CanvasSchema.execute(mutation_str(item_ids: reordered_ids), context:)

      module1.reload
      ordered_items = module1.content_tags.ordered
      positions = ordered_items.map(&:position)

      # Positions should be sequential starting from 1
      expect(positions).to eq [1, 2, 3]
    end

    it "updates module timestamps" do
      original_time = module1.updated_at
      Timecop.travel(1.second.from_now) do
        CanvasSchema.execute(mutation_str, context:)
      end

      module1.reload
      expect(module1.updated_at).to be > original_time
    end

    it "handles concurrent modifications gracefully" do
      # This test ensures the transaction rollback works properly
      allow(ContentTag).to receive(:transaction).and_raise(StandardError, "Simulated error")

      result = CanvasSchema.execute(mutation_str, context:)
      expect(result.dig("data", "reorderModuleItems", "errors", 0, "message")).to eq "Simulated error"

      # Verify no changes were made
      module1.reload
      original_order = [item1.id, item2.id, item3.id]
      expect(module1.content_tags.ordered.map(&:id)).to eq original_order
    end
  end

  describe "edge cases" do
    let(:context) { { current_user: teacher } }

    it "handles modules with single item" do
      single_module = course.context_modules.create!(name: "Single Item Module")
      single_assignment = course.assignments.create!(title: "Single Assignment")
      single_item = single_module.add_item(id: single_assignment.id, type: "assignment")

      result = CanvasSchema.execute(
        mutation_str(
          module_id: single_module.id,
          item_ids: [single_item.id]
        ),
        context:
      )

      expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil
      expect(result.dig("data", "reorderModuleItems", "module", "_id")).to eq single_module.id.to_s
    end

    it "handles large number of items" do
      # Create a module with many items
      large_module = course.context_modules.create!(name: "Large Module")
      large_items = []

      20.times do |i|
        assignment = course.assignments.create!(title: "Assignment #{i + 1}")
        large_items << large_module.add_item(id: assignment.id, type: "assignment")
      end

      # Reverse the order
      reversed_ids = large_items.map(&:id).reverse

      result = CanvasSchema.execute(
        mutation_str(
          module_id: large_module.id,
          item_ids: reversed_ids
        ),
        context:
      )

      expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil

      large_module.reload
      expect(large_module.content_tags.ordered.map(&:id)).to eq reversed_ids
    end

    it "moves an item down within the same module using target_position" do
      reordered_ids = [item1.id]
      result = CanvasSchema.execute(
        mutation_str(item_ids: reordered_ids, target_position: 3),
        context: { current_user: teacher }
      )

      expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil
      module1.reload
      expect(module1.content_tags.ordered.map(&:id)).to eq [item2.id, item1.id, item3.id]
    end

    it "inserts an item at the very top with target_position = 1" do
      reordered_ids = [item2.id]
      result = CanvasSchema.execute(
        mutation_str(item_ids: reordered_ids, target_position: 1),
        context: { current_user: teacher }
      )

      expect(result.dig("data", "reorderModuleItems", "errors")).to be_nil
      module1.reload
      expect(module1.content_tags.ordered.first.id).to eq item2.id
    end
  end
end
