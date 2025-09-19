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
      items = ContentTag.where(id: item_ids, context: course)
      return { success: false, error: "One or more items not found" } unless items.count == item_ids.length

      source_items = items.where(context_module_id: source_module.id)
      return { success: false, error: "Items do not belong to source module" } unless source_items.count == items.count

      items_by_id   = items.index_by(&:id)
      ordered_items = item_ids.filter_map { |id| items_by_id[id.to_i] }

      affected_items, affected_module_ids =
        apply_reordering(ordered_items, target_module, source_module, target_position)

      touched_module_ids = ([target_module.id] + affected_module_ids.to_a).uniq
      touched_module_ids.each { |mid| reindex_module_items(mid) }

      ContentTag.update_could_be_locked(affected_items)
      ContentTag.touch_context_modules(touched_module_ids)
      course.touch

      { success: true }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def apply_reordering(ordered_items, target_module, source_module, target_position)
    affected_items      = []
    affected_module_ids = Set.new

    ordered_items.each_with_index do |item, index|
      old_module_id = item.context_module_id

      position = final_position_for(
        item,
        index,
        target_module:,
        source_module:,
        target_position:
      )

      item.update!(context_module_id: target_module.id, position:, skip_touch: true)
      affected_items << item
      affected_module_ids << old_module_id if old_module_id != target_module.id
    end

    [affected_items, affected_module_ids]
  end

  def final_position_for(item, index, target_module:, source_module:, target_position:)
    # baseline position
    position =
      if target_position == 1 && index.zero?
        0
      else
        target_position ? target_position + index : index + 1
      end

    # decide whether to bump
    should_bump =
      if source_module == target_module
        item.position > position || (target_position && item.position < target_position)
      else
        true
      end

    position_scope = target_module.content_tags.where.not(workflow_state: "deleted")
    if should_bump
      position_scope.where(position: position..).update_all("position = position + 1")
    elsif target_position && item.position < target_position
      max_position = target_module.content_tags.active.maximum(:position) || 0
      position -= 1 unless target_position >= max_position
    end

    position
  end

  def reindex_module_items(module_id)
    items = ContentTag.where(context_module_id: module_id)
                      .where.not(workflow_state: "deleted")
                      .order(:position, :id)

    items.each_with_index do |item, idx|
      desired = idx + 1
      item.update_columns(position: desired, updated_at: Time.current) if item.position != desired
    end
  end
end
