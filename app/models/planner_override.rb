#
# Copyright (C) 2017 Instructure, Inc.
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

class PlannerOverride < ActiveRecord::Base
  CONTENT_TYPES = %w(Announcement Assignment DiscussionTopic Quizzes::Quiz WikiPage).freeze

  include Workflow
  belongs_to :plannable, polymorphic: true
  belongs_to :user
  validates_inclusion_of :plannable_type, :allow_nil => false, :in => CONTENT_TYPES
  validates_presence_of :plannable_id, :workflow_state, :user_id

  scope :active, -> { where workflow_state: 'active' }
  scope :visible, -> { where visible: true }
  scope :hidden, -> { where.not visible }
  scope :deleted, -> { where workflow_state: 'deleted' }
  scope :not_deleted, -> { where.not deleted }

  workflow do
    state :active do
      event :unpublish, :transitions_to => :unpublished
    end
    state :unpublished do
      event :publish, :transitions_to => :active
    end
    state :deleted
  end

  alias_method :published?, :active?

  def self.update_for(obj)
    overrides = PlannerOverride.where(plannable_id: obj.id, plannable_type: obj.class.to_s)
    overrides.update_all(workflow_state: plannable_workflow_state(obj)) if overrides.exists?
  end

  def self.for_user(user)
    overrides = PlannerOverride.where(user_id: user)
  end

  def self.plannable_workflow_state(plannable)
    if plannable.respond_to?(:published?)
      if plannable.respond_to?(:deleted?) && plannable.deleted?
        'deleted'
      elsif plannable.published?
        'active'
      else
        'unpublished'
      end
    else
      if plannable.respond_to?(:workflow_state)
        workflow_state = plannable.workflow_state.to_s
        if ['active', 'available', 'published'].include?(workflow_state)
          'active'
        elsif ['unpublished', 'deleted'].include?(workflow_state)
          workflow_state
        end
      else
        nil
      end
    end
  end

  def plannable_workflow_state
    PlannerOverride.plannable_workflow_state(self.plannable)
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    self.save
  end
end
