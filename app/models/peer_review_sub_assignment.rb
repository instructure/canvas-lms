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
  has_many :assessment_requests

  validates :parent_assignment_id,
            presence: true,
            uniqueness: { conditions: -> { where.not(workflow_state: "deleted") } },
            comparison: { other_than: :id, message: ->(_object, _data) { I18n.t("cannot reference self") }, allow_blank: true }
  validates :has_sub_assignments, inclusion: { in: [false], message: I18n.t("cannot have sub assignments") }
  validates :sub_assignment_tag, absence: { message: ->(_object, _data) { I18n.t("cannot have sub assignment tag") } }
  validate  :context_matches_parent_assignment

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

  def governs_submittable?
    false
  end

  private

  def context_matches_parent_assignment
    return true if context_id == parent_assignment&.context_id

    errors.add(:context, I18n.t("must match parent assignment context"))
  end
end
