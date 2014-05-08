#
# Copyright (C) 2011 Instructure, Inc.
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
  attr_accessible :rubric_assessment, :user, :asset, :assessor_asset, :comments, :rubric_association, :assessor
  EXPORTABLE_ATTRIBUTES = [
    :id, :rubric_assessment_id, :user_id, :asset_id, :asset_type, :assessor_asset_id, :assessor_asset_type,
    :comments, :workflow_state, :created_at, :updated_at, :uuid, :rubric_association_id, :assessor_id
  ]

  EXPORTABLE_ASSOCIATIONS = [:user, :asset, :assessor_asset, :submission, :submission_comments, :rubric_assessment]

  belongs_to :user
  belongs_to :asset, :polymorphic => true
  validates_inclusion_of :asset_type, :allow_nil => true, :in => ['Submission']
  belongs_to :assessor_asset, :polymorphic => true
  validates_inclusion_of :assessor_asset_type, :allow_nil => true, :in => ['Submission', 'User']
  belongs_to :assessor, :class_name => 'User'
  belongs_to :submission, :foreign_key => 'asset_id'
  belongs_to :rubric_association
  has_many :submission_comments
  belongs_to :rubric_assessment
  validates_presence_of :user_id, :asset_id, :asset_type, :workflow_state
  validates_length_of :comments, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true

  before_save :infer_uuid
  has_a_broadcast_policy

  def infer_uuid
    self.uuid ||= CanvasUuid::Uuid.generate_securish_uuid
  end
  protected :infer_uuid

  set_broadcast_policy do |p|
    p.dispatch :rubric_assessment_submission_reminder
    p.to { self.assessor }
    p.whenever { |record|
      record.assigned? && @send_reminder
    }
  end

  scope :incomplete, where(:workflow_state => 'assigned')
  scope :for_assessee, lambda { |user_id| where(:user_id => user_id) }

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

  def asset_context_name
    (self.asset.context.name rescue self.asset.assignment.context.name) rescue t("#unknown", "Unknown")
  end

  def self.serialization_excludes; [:uuid]; end
end
