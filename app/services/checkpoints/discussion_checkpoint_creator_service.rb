# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class Checkpoints::DiscussionCheckpointCreatorService < Checkpoints::DiscussionCheckpointCommonService
  def call
    validate_flag_enabled
    validate_dates

    checkpoint = create_checkpoint
    compute_due_dates_and_create_submissions(checkpoint)
    checkpoint
  end

  private

  def create_checkpoint
    AbstractAssignment.suspend_due_date_caching_and_score_recalculation do
      @discussion_topic.update!(reply_to_entry_required_count: @replies_required) if update_required_replies?
      checkpoint = @assignment.sub_assignments.create!(checkpoint_attributes)
      Checkpoints::DateOverrideCreatorService.call(checkpoint:, overrides: override_dates) if override_dates.any?
      update_assignment
      checkpoint
    end
  end
end
