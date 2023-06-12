# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
  include Workflow

  CONTENT_TYPES = PlannerHelper::PLANNABLE_TYPES.values

  before_validation :link_to_parent_topic, :link_to_submittable

  belongs_to :plannable, polymorphic:
    [:announcement,
     :assignment,
     :discussion_topic,
     :planner_note,
     :wiki_page,
     :calendar_event,
     :assessment_request,
     quiz: "Quizzes::Quiz"]
  belongs_to :user
  validates :plannable_id, :plannable_type, :workflow_state, :user_id, presence: true
  validates :plannable_id, uniqueness: { scope: [:user_id, :plannable_type] }

  scope :active, -> { where workflow_state: "active" }
  scope :deleted, -> { where workflow_state: "deleted" }
  scope :not_deleted, -> { where.not deleted }
  scope :for_user, ->(user) { where user: }

  workflow do
    state :active do
      event :unpublish, transitions_to: :unpublished
    end
    state :unpublished do
      event :publish, transitions_to: :active
    end
    state :deleted
  end

  alias_method :published?, :active?

  def link_to_parent_topic
    return unless plannable_type == "DiscussionTopic"

    plannable = DiscussionTopic.find(plannable_id)
    self.plannable_id = plannable.root_topic_id if plannable.root_topic_id
  end

  def link_to_submittable
    return unless plannable_type == "Assignment"

    plannable = Assignment.find_by(id: plannable_id)
    if plannable&.quiz?
      self.plannable_type = PlannerHelper::PLANNABLE_TYPES["quiz"]
      self.plannable_id = plannable.quiz.id
    elsif plannable&.discussion_topic?
      self.plannable_type = PlannerHelper::PLANNABLE_TYPES["discussion_topic"]
      self.plannable_id = plannable.discussion_topic.id
    elsif plannable&.wiki_page?
      self.plannable_type = PlannerHelper::PLANNABLE_TYPES["wiki_page"]
      self.plannable_id = plannable.wiki_page.id
    end
  end

  def associated_assignment_id
    return plannable_id if plannable_type == "Assignment"

    plannable.assignment_id if plannable.respond_to? :assignment_id
  end

  def self.update_for(obj)
    overrides = PlannerOverride.where(plannable_id: obj.id, plannable_type: obj.class.to_s)
    overrides.update_all(workflow_state: plannable_workflow_state(obj)) if overrides.exists?
  end

  def self.plannable_workflow_state(plannable)
    if plannable.respond_to?(:published?)
      if plannable.respond_to?(:deleted?) && plannable.deleted?
        "deleted"
      elsif plannable.published?
        "active"
      else
        "unpublished"
      end
    elsif plannable.respond_to?(:workflow_state)
      workflow_state = plannable.workflow_state.to_s
      if %w[active available published].include?(workflow_state)
        "active"
      elsif ["unpublished", "deleted"].include?(workflow_state)
        workflow_state
      end
    else
      "unpublished"
    end
  end

  def plannable_workflow_state
    PlannerOverride.plannable_workflow_state(plannable)
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save
  end
end
