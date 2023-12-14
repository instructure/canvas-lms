# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AssessmentRequest < ActiveRecord::Base
  include Workflow
  include SendToStream
  include Plannable

  belongs_to :user
  belongs_to :asset, polymorphic: [:submission]
  belongs_to :assessor_asset, polymorphic: [:submission], polymorphic_prefix: true
  belongs_to :assessor, class_name: "User"
  belongs_to :rubric_association
  has_many :submission_comments, -> { published }
  has_many :ignores, dependent: :destroy, as: :asset
  belongs_to :rubric_assessment
  validates :user_id, :asset_id, :asset_type, :workflow_state, presence: true

  before_save :infer_uuid
  after_save :delete_ignores
  after_save :update_planner_override
  has_a_broadcast_policy

  def infer_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :infer_uuid

  def delete_ignores
    if workflow_state == "completed"
      Ignore.where(asset: self, user: assessor).delete_all
    end
    true
  end

  def course_broadcast_data
    context&.broadcast_data
  end

  set_broadcast_policy do |p|
    p.dispatch :rubric_assessment_submission_reminder
    p.to { assessor }
    p.whenever do
      should_send_reminder? && active_rubric_association?
    end
    p.data { course_broadcast_data }

    p.dispatch :peer_review_invitation
    p.to { assessor }
    p.whenever do
      should_send_reminder? && !active_rubric_association?
    end
    p.data { course_broadcast_data }
  end

  scope :incomplete, -> { where(workflow_state: "assigned") }
  scope :complete, -> { where(workflow_state: "completed") }
  scope :for_assessee, ->(user_id) { where(user_id:) }
  scope :for_assessor, ->(assessor_id) { where(assessor_id:) }
  scope :for_asset, ->(asset_id) { where(asset_id:) }
  scope :for_assignment, ->(assignment_id) { eager_load(:submission).where(submissions: { assignment_id: }) }
  scope :for_courses, ->(courses) { eager_load(:submission).where(submissions: { course_id: courses }) }
  scope :for_active_users, lambda { |course|
    current_enrollments = course.current_enrollments.pluck(:user_id)
    where(user_id: current_enrollments)
  }
  scope :for_active_assessors, lambda { |course|
                                 current_enrollments = course.current_enrollments.pluck(:user_id)
                                 where(assessor_id: current_enrollments)
                               }

  scope :not_ignored_by, lambda { |user, purpose|
    where.not(
      Ignore.where("asset_id=assessment_requests.id")
          .where(asset_type: "AssessmentRequest", user_id: user, purpose:)
          .arel.exists
    )
  }

  set_policy do
    given do |user, session|
      can_read_assessment_user_name?(user, session)
    end
    can :read_assessment_user
  end

  def can_read_assessment_user_name?(user, session)
    !considered_anonymous? ||
      user_id == user.id ||
      submission.assignment.context.grants_right?(user, session, :view_all_grades)
  end

  def considered_anonymous?
    submission.assignment.anonymous_peer_reviews?
  end

  def send_reminder!
    @send_reminder = true
    self.updated_at = Time.now
    save!
  ensure
    @send_reminder = nil
  end

  def should_send_reminder?
    # Do not send notifications if the context is an unpublished course
    return false if context.is_a?(Course) && !context.published?

    # or if the asset is a submission and the assignment is unpublished
    return false if asset.is_a?(Submission) && asset.assignment.workflow_state != "published"

    @send_reminder && assigned?
  end

  def context
    submission.try(:context)
  end

  def assessor_name
    rubric_assessment.assessor_name rescue ((assessor.name rescue nil) || t("#unknown", "Unknown"))
  end

  def incomplete?
    workflow_state == "assigned"
  end

  def available?
    assignment = (assessor_asset || asset).assignment
    assignment&.submitted?(submission: asset) && assignment.submitted?(submission: assessor_asset)
  end

  on_create_send_to_streams do
    assessor
  end
  on_update_send_to_streams do
    assessor
  end

  workflow do
    state :assigned do
      event :complete, transitions_to: :completed
    end

    # assessment request now has rubric_assessment
    state :completed
  end

  def asset_title
    (asset.assignment.title rescue asset.title) rescue t("#unknown", "Unknown")
  end

  def comment_added
    self.workflow_state = "completed" unless active_rubric_association? && rubric_association.rubric
  end

  def asset_user_name
    asset.user.name rescue t("#unknown", "Unknown")
  end

  def self.serialization_excludes
    [:uuid]
  end

  def update_planner_override
    if saved_change_to_workflow_state? && workflow_state_before_last_save == "assigned" && workflow_state == "completed"
      override = PlannerOverride.find_by(plannable_id: id, plannable_type: "AssessmentRequest", user: assessor)
      override.update(marked_complete: true) if override.present?
    end
  end

  def active_rubric_association?
    !!rubric_association&.active?
  end
end
