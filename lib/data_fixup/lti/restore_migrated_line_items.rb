# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup::Lti::RestoreMigratedLineItems
  def self.run
    # External tool assignments deleted and re-imported after this date
    # will still have deleted LTI models that should also be restored.
    # see ab3c08cc6b1d4e659a252430b561caf53a28a7fe
    start_date = Time.zone.parse("2023-11-15")

    GuardRail.activate(:secondary) do
      Assignment
        .joins(:line_items)
        .where(submission_types: "external_tool", created_at: start_date.., line_items: { workflow_state: :deleted })
        .where.not(workflow_state: :deleted)
        .find_ids_in_batches do |ids|
          GuardRail.activate(:primary) { process_batch(ids) }
        end
    end
  end

  def self.process_batch(assignment_ids)
    Lti::ResourceLink
      .where(workflow_state: :deleted, context_type: "Assignment", context_id: assignment_ids)
      .update_all(workflow_state: :active)
    ContentTag
      .where(workflow_state: :deleted, content_type: "ContextExternalTool", context_type: "Assignment", context_id: assignment_ids)
      .update_all(workflow_state: :active)

    # always restore all primary line items, meaning:
    # the earliest created line item for each assignment
    line_item_ids = Lti::LineItem
                    .where(workflow_state: :deleted, assignment_id: assignment_ids)
                    .order(:assignment_id, :created_at)
                    .select("DISTINCT ON (assignment_id) id")
                    .map(&:id) # can't just use .ids because it ruins the "select DISTINCT ON ..."
    Lti::LineItem.where(id: line_item_ids).update_all(workflow_state: :active)

    # restore any extra line items that were not user-deleted via AGS, meaning:
    # extra line items that were deleted at roughly the same time as the assignment and primary line item
    extra_line_item_ids = Assignment
                          .joins(:line_items)
                          .preload(:line_items)
                          .where(id: assignment_ids)
                          .group("assignments.id")
                          .having("count(assignment_id) > 1")
                          .flat_map do |assignment|
      # use array methods instead of SQL to avoid a subquery
      primary = assignment.line_items.min_by(&:created_at)
      t = primary.updated_at

      assignment.line_items.filter do |li|
        li.id != primary.id && li.updated_at.between?(t - 1.second, t + 1.second)
      end.pluck(:id)
    end
    Lti::LineItem.where(id: extra_line_item_ids).update_all(workflow_state: :active) if extra_line_item_ids.present?

    Lti::Result
      .where(workflow_state: :deleted, lti_line_item_id: line_item_ids + extra_line_item_ids)
      .update_all(workflow_state: :active)
  end
end
