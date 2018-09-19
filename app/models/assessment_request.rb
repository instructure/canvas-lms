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

  belongs_to :user
  belongs_to :asset, polymorphic: [:submission]
  belongs_to :assessor_asset, polymorphic: [:submission, :user], polymorphic_prefix: true
  belongs_to :assessor, :class_name => 'User'
  belongs_to :rubric_association
  has_many :submission_comments, -> { published }
  has_many :ignores, dependent: :destroy, as: :asset
  belongs_to :rubric_assessment
  validates_presence_of :user_id, :asset_id, :asset_type, :workflow_state

  before_save :infer_uuid
  after_save :delete_ignores
  has_a_broadcast_policy

  def infer_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :infer_uuid

  def delete_ignores
    if workflow_state == 'completed'
      Ignore.where(asset: self, user: assessor).delete_all
    end
    true
  end

  set_broadcast_policy do |p|
    p.dispatch :rubric_assessment_submission_reminder
    p.to { self.assessor }
    p.whenever { |record|
      record.assigned? && @send_reminder && rubric_association
    }

    p.dispatch :peer_review_invitation
    p.to { self.assessor }
    p.whenever { |record|
      record.assigned? && @send_reminder && !rubric_association
    }
  end

  scope :incomplete, -> { where(:workflow_state => 'assigned') }
  scope :complete, -> { where(:workflow_state => 'completed') }
  scope :for_assessee, lambda { |user_id| where(:user_id => user_id) }
  scope :for_assessor, lambda { |assessor_id| where(:assessor_id => assessor_id) }
  scope :for_asset, lambda { |asset_id| where(:asset_id => asset_id)}
  scope :for_assignment, lambda { |assignment_id| eager_load(:submission).where(:submissions => { :assignment_id => assignment_id})}
  scope :for_course, lambda { |course_id| eager_load(:submission).where(:submissions => { :context_code => "course_#{course_id}"})}
  scope :for_context_codes, lambda { |context_codes| eager_load(:submission).where(:submissions => { :context_code =>context_codes })}

  scope :not_ignored_by, lambda { |user, purpose|
    where("NOT EXISTS (?)",
          Ignore.where("asset_id=assessment_requests.id").
              where(asset_type: 'AssessmentRequest', user_id: user, purpose: purpose))
  }

  set_policy do
    given {|user, session|
      self.can_read_assessment_user_name?(user, session)
    }
    can :read_assessment_user
  end

  def can_read_assessment_user_name?(user, session)
    !self.considered_anonymous? ||
        self.user_id == user.id ||
        self.submission.assignment.context.grants_right?(user, session, :view_all_grades)
  end

  def considered_anonymous?
    self.submission.assignment.anonymous_peer_reviews?
  end

  def send_reminder!
    @send_reminder = true
    self.updated_at = Time.now
    self.save!
  ensure
    @send_reminder = nil
  end

  def context
    submission.try(:context)
  end

  def assessor_name
    self.rubric_assessment.assessor_name rescue ((self.assessor.name rescue nil) || t("#unknown", "Unknown"))
  end

  def incomplete?
    workflow_state == 'assigned'
  end

  on_create_send_to_streams do
    self.assessor
  end
  on_update_send_to_streams do
    self.assessor
  end

  workflow do
    state :assigned do
      event :complete, :transitions_to => :completed
    end

    # assessment request now has rubric_assessment
    state :completed
  end

  def asset_title
    (self.asset.assignment.title rescue self.asset.title) rescue t("#unknown", "Unknown")
  end

  def comment_added(comment)
    self.workflow_state = "completed" unless self.rubric_association && self.rubric_association.rubric
  end

  def asset_user_name
    self.asset.user.name rescue t("#unknown", "Unknown")
  end

  def self.serialization_excludes; [:uuid]; end
end
