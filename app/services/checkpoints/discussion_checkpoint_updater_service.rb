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

class Checkpoints::DiscussionCheckpointUpdaterService < Checkpoints::DiscussionCheckpointCommonService
  def call
    validate_flag_enabled
    validate_dates

    checkpoint = find_checkpoint
    compute_due_dates_and_create_submissions(checkpoint)
    checkpoint.save
    checkpoint
  end

  private

  def find_checkpoint
    AbstractAssignment.suspend_due_date_caching_and_score_recalculation do
      @discussion_topic.update!(reply_to_entry_required_count: @replies_required) if update_required_replies?
      checkpoint = @assignment.sub_assignments.find_by(sub_assignment_tag: @checkpoint_label)

      raise Checkpoints::CheckpointNotFoundError, "Checkpoint '#{@checkpoint_label}' not found" unless checkpoint

      checkpoint.assign_attributes(checkpoint_attributes)

      update_overrides = override_dates.select { |override| override[:id].present? }
      new_overrides = override_dates.select { |override| override[:id].nil? }
      existing_overrides = checkpoint.assignment_overrides

      override_ids_to_delete = existing_overrides.pluck(:id) - update_overrides.pluck(:id)

      # 1. Update existing overrides.
      Checkpoints::DateOverrideUpdaterService.call(checkpoint:, overrides: update_overrides) if update_overrides.any?

      # 2. Add new overrides
      Checkpoints::DateOverrideCreatorService.call(checkpoint:, overrides: new_overrides) if new_overrides.any?

      # 3. Remove overrides that are no longer present
      checkpoint.assignment_overrides.where(id: override_ids_to_delete).destroy_all if override_ids_to_delete.any?

      update_assignment
      checkpoint
    end
  end
end
