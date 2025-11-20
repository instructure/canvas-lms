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

class PeerReviewSubAssignment < AbstractAssignment
  belongs_to :parent_assignment, class_name: "Assignment", inverse_of: :peer_review_sub_assignment
  has_many :assessment_requests, dependent: :nullify

  SYNCABLE_ATTRIBUTES = %w[
    anonymous_peer_reviews
    assignment_group_id
    automatic_peer_reviews
    context_id
    context_type
    description
    group_category_id
    intra_group_peer_reviews
    peer_review_count
    peer_reviews
    peer_reviews_assigned
    peer_reviews_due_at
    title
    workflow_state
  ].freeze

  validates :parent_assignment_id,
            presence: true,
            uniqueness: { conditions: -> { where.not(workflow_state: "deleted") } },
            comparison: { other_than: :id, message: ->(_object, _data) { I18n.t("cannot reference self") }, allow_blank: true }
  validates :has_sub_assignments, inclusion: { in: [false], message: ->(_object, _data) { I18n.t("cannot have sub assignments") } }
  validates :sub_assignment_tag, absence: { message: ->(_object, _data) { I18n.t("cannot have sub assignment tag") } }
  validate  :context_matches_parent_assignment, if: :context_explicitly_provided?
  validate  :parent_assignment_not_discussion_topic_or_external_tool

  after_initialize :set_default_context
  after_save :unlink_assessment_requests, if: :soft_deleted?

  # TODO: update broadcast policy (EGG-1672)
  set_broadcast_policy do |p|
    p.dispatch :peer_review_sub_assignment_created
    p.to do |assignment|
      BroadcastPolicies::AssignmentParticipants.new(assignment).to
    end
    p.whenever do
      true
    end
  end

  def checkpoint?
    false
  end

  def checkpoints_parent?
    false
  end

  def effective_group_category_id
    group_category_id
  end

  def governs_submittable?
    false
  end

  private

  def set_default_context
    if context.nil?
      self.context = parent_assignment&.context
    else
      @context_explicitly_provided = true
    end
  end

  def context_explicitly_provided?
    @context_explicitly_provided == true
  end

  def context_matches_parent_assignment
    return true if context_id == parent_assignment&.context_id

    errors.add(:context, I18n.t("must match parent assignment context"))
  end

  def parent_assignment_not_discussion_topic_or_external_tool
    assignment = parent_assignment
    return unless assignment

    if assignment.submission_types == "discussion_topic"
      errors.add(:parent_assignment, I18n.t("cannot be a discussion topic"))
    elsif assignment.external_tool?
      errors.add(:parent_assignment, I18n.t("cannot be an external tool"))
    end
  end

  def soft_deleted?
    saved_change_to_workflow_state? && workflow_state == "deleted"
  end

  def unlink_assessment_requests
    assessment_requests.update_all(peer_review_sub_assignment_id: nil)
  end
end
