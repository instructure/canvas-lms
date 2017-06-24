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

module Plannable
  ACTIVE_WORKFLOW_STATES = ['active', 'published'].freeze

  def self.included(base)
    base.class_eval do
      has_many :planner_overrides, as: :plannable
      after_save :update_associated_planner_overrides
      before_save :check_if_associated_planner_overrides_need_updating
      scope :available_to_planner, -> { where(workflow_state: ACTIVE_WORKFLOW_STATES) }
    end
  end

  def update_associated_planner_overrides_later
    send_later(:update_associated_planner_overrides) if @associated_planner_items_need_updating != false
  end

  def update_associated_planner_overrides
    PlannerOverride.update_for(self) if @associated_planner_items_need_updating
  end

  def check_if_associated_planner_overrides_need_updating
    @associated_planner_items_need_updating = false
    return if self.new_record?
    return if self.respond_to?(:context_type) && !PlannerOverride::CONTENT_TYPES.include?(self.context_type)
    @associated_planner_items_need_updating = true if self.respond_to?(:workflow_state_changed?) && self.workflow_state_changed? || self.workflow_state == 'deleted'
  end

  def visible_in_planner_for?(user)
    return true unless planner_enabled?
    self.planner_overrides.where(user_id: user,
                                 visible: false,
                                 workflow_state: 'active'
                                ).blank?
  end

  def planner_override_for(user)
    return nil unless planner_enabled?
    self.planner_overrides.where(user_id: user).take
  end
  private

  def planner_enabled?
    root_account_for_model(self).feature_enabled?(:student_planner)
  end

  def root_account_for_model(base)
    case base
    when PlannerNote
      base.user.account
    else
      base.context.root_account
    end
  end
end
