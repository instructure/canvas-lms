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

module Factories
  def planner_override_model(opts={})
    user = opts[:user] || @user || user_model
    plannable = opts[:plannable] || assignment_model
    visibility = opts.key?(:marked_complete) ? opts[:marked_complete] : false
    attrs = { user_id: user.id,
              plannable_type: plannable.class.to_s,
              plannable_id: plannable.id,
              marked_complete: visibility }
    @planner_override = PlannerOverride.create!(valid_planner_override_attributes.merge(attrs))
  end

  def valid_planner_override_attributes
    {
      :marked_complete => false
    }
  end
end
