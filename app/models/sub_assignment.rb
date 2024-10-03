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

  has_one :discussion_topic, through: :parent_assignment

  SUB_ASSIGNMENT_SYNC_ATTRIBUTES = %w[unlock_at lock_at].freeze
  after_save :sync_with_parent, if: :should_sync_with_parent?
  after_commit :aggregate_checkpoint_assignments, if: :checkpoint_changes?

  set_broadcast_policy do |p|
    p.dispatch :checkpoints_created
    p.to do |assignment|
      BroadcastPolicies::AssignmentParticipants.new(assignment).to
    end
    p.whenever do |assignment|
      BroadcastPolicies::AssignmentPolicy.new(assignment)
                                         .should_dispatch_assignment_created?
    end
    p.data { course_broadcast_data }
    p.filter_asset_by_recipient do |assignment, user|
      assignment.overridden_for(user, skip_clone: true)
    end
  end

  delegate :effective_group_category_id, to: :parent_assignment

  def checkpoint?
    true
  end

  def checkpoints_parent?
    false
  end

  private

  def sync_with_parent
    return if saved_by == :parent_assignment

    changed_attributes = previous_changes.slice(*SUB_ASSIGNMENT_SYNC_ATTRIBUTES)
    parent_assignment.update_from_sub_assignment(changed_attributes)
  end

  def should_sync_with_parent?
    sync_attributes_changed? && saved_by != :parent_assignment
  end

  def sync_attributes_changed?
    previous_changes.keys.intersect?(SUB_ASSIGNMENT_SYNC_ATTRIBUTES)
  end

  def sync_attributes_changes
    previous_changes.slice(*SUB_ASSIGNMENT_SYNC_ATTRIBUTES)
  end

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

  # visibility of sub_assignments is determined by the visibility of their parent assignment
  scope :visible_to_students_in_course_with_da, lambda { |user_ids, course_ids|
    if Account.site_admin.feature_enabled?(:selective_release_backend)
      visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students_in_courses(user_ids:, course_ids:).map(&:assignment_id)
      if visible_assignment_ids.any?
        where(parent_assignment_id: visible_assignment_ids)
      else
        none
      end
    else
      joins("JOIN #{AssignmentStudentVisibility.quoted_table_name} AS asv ON asv.assignment_id = assignments.parent_assignment_id")
        .where("assignments.context_id IN (?)
          AND assignments.context_type = 'Course'
          AND asv.course_id IN (?)
          AND asv.user_id = ANY( '{?}'::INT8[] )
        ",
               course_ids,
               course_ids,
               user_ids)
    end
  }
end
