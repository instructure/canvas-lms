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
#

class SubAssignment < AbstractAssignment
  validates :parent_assignment_id, presence: true, comparison: { other_than: :id, message: -> { I18n.t("cannot reference self") }, allow_blank: true }
  validates :has_sub_assignments, inclusion: { in: [false], message: -> { I18n.t("cannot be true for sub assignments") } }
  validates :sub_assignment_tag, inclusion: { in: [CheckpointLabels::REPLY_TO_TOPIC, CheckpointLabels::REPLY_TO_ENTRY] }

  after_commit :aggregate_checkpoint_assignments, if: :checkpoint_changes?

  set_broadcast_policy do
    # TODO: define broadcast policies for checkpoints
  end

  delegate :effective_group_category_id, to: :parent_assignment

  def checkpoint?
    true
  end

  private

  def aggregate_checkpoint_assignments
    Checkpoints::AssignmentAggregatorService.call(assignment: parent_assignment)
  end

  def checkpoint_changes?
    !!root_account&.feature_enabled?(:discussion_checkpoints) && checkpoint_attributes_changed?
  end

  def checkpoint_attributes_changed?
    tracked_attributes = Checkpoints::AssignmentAggregatorService::AggregateAssignment.members.map(&:to_s) - ["updated_at"]
    relevant_changes = tracked_attributes & previous_changes.keys
    relevant_changes.any?
  end

  def governs_submittable?
    false
  end
end
