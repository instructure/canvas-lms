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

class Mutations::ReorderModuleItems < Mutations::BaseMutation
  argument :course_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")
  argument :item_ids, [ID], required: true, prepare: :prepare_item_ids
  argument :module_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("ContextModule")
  argument :old_module_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("ContextModule")
  argument :target_position, Integer, required: false

  field :module, Types::ModuleType, null: true, resolver_method: :context_module
  def context_module
    object[:module]
  end

  field :old_module, Types::ModuleType, null: true

  def resolve(input:)
    course = Course.find(input[:course_id])
    target_module = course.context_modules.find(input[:module_id])
    source_module = input[:old_module_id] ? course.context_modules.find(input[:old_module_id]) : target_module

    verify_authorized_action!(target_module, :update)
    verify_authorized_action!(source_module, :update) if source_module != target_module

    result = reorder_items(
      course:,
      target_module:,
      source_module:,
      item_ids: input[:item_ids],
      target_position: input[:target_position]
    )

    if result[:success]
      {
        module: target_module.reload,
        old_module: (source_module == target_module) ? nil : source_module.reload
      }
    else
      validation_error(result[:error])
    end
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end

  def self.prepare_item_ids(ids, _ctx)
    ids.map { |id| GraphQLHelpers.parse_relay_or_legacy_id(id, "ContentTag") }
  end

  private

  def reorder_items(course:, target_module:, source_module:, item_ids:, target_position: nil)
    ContentTag.transaction do
      # Validate all items exist and belong to the course
      items = ContentTag.where(id: item_ids, context: course)

      unless items.count == item_ids.length
        return { success: false, error: "One or more items not found" }
      end

      # Check that items belong to source module
      source_items = items.where(context_module_id: source_module.id)
      unless source_items.count == items.count
        return { success: false, error: "Items do not belong to source module" }
      end

      # Get items in the order they were specified - use hash for O(1) lookup
      items_by_id = items.index_by(&:id)
      ordered_items = item_ids.filter_map { |item_id| items_by_id[item_id.to_i] }

      affected_module_ids = Set.new

      affected_items = []

      if source_module == target_module
        # Same module reordering - need to handle position conflicts properly
        if target_position
          # Use provided target position and shift existing items
          ordered_items.each_with_index do |item, index|
            position_to_use = target_position + index

            # Shift existing items that need to move down
            source_module.content_tags.active.where(position: position_to_use..).where.not(id: item_ids).update_all("position = position + 1")

            item.position = position_to_use
            next unless item.changed?

            item.skip_touch = true
            item.save!
            affected_items << item
          end
        else
          # No target position - place specified items at the beginning and shift remaining items
          ordered_items.each_with_index do |item, index|
            new_position = index + 1
            item.position = new_position
            next unless item.changed?

            item.skip_touch = true
            item.save!
            affected_items << item
          end

          # Shift remaining items that are not being reordered to positions after the reordered items
          remaining_items = source_module.content_tags.active.where.not(id: item_ids).order(:position)
          next_position = ordered_items.length + 1

          remaining_items.each do |item|
            if item.position != next_position
              item.position = next_position
              item.skip_touch = true
              item.save!
              affected_items << item
            end
            next_position += 1
          end
        end
      else
        # Cross-module move - manually handle position management to ensure correct ordering

        ordered_items.each_with_index do |item, index|
          old_module_id = item.context_module_id
          # Use provided target_position or default to array index + 1
          position_to_use = target_position ? target_position + index : index + 1

          # First, shift existing items that need to move down
          # We need to do this BEFORE moving the new item to avoid position conflicts
          target_module.content_tags.active.where(position: position_to_use..).update_all("position = position + 1")

          # Then move item to target module at the desired position
          item.context_module_id = target_module.id
          item.position = position_to_use
          item.skip_touch = true
          item.save!

          affected_items << item
          affected_module_ids << old_module_id if old_module_id != target_module.id
        end

        # Reindex remaining items in affected source modules to close gaps
        affected_module_ids.each do |module_id|
          reindex_module_items(module_id)
        end
      end

      # Update content tag contexts and touch modules (handles cache invalidation)
      ContentTag.update_could_be_locked(affected_items)
      module_ids_to_touch = [target_module.id] + affected_module_ids.to_a
      ContentTag.touch_context_modules(module_ids_to_touch.uniq)
      course.touch

      { success: true }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def reindex_module_items(module_id)
    ContextModule.find(module_id).content_tags.active.order(:position).each_with_index do |item, index|
      item.update_column(:position, index + 1)
    end
  end
end
