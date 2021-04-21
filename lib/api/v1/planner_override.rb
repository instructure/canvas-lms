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

module Api::V1::PlannerOverride
  include Api::V1::Json
  include PlannerApiHelper

  def planner_override_json(override, user, session, type=nil)
    return if override.blank?
    json = api_json(override, user, session)
    type = override.plannable.type if override.plannable_type == 'DiscussionTopic' && type.nil?
    json['plannable_type'] = PlannerHelper::PLANNABLE_TYPES.key(type || json['plannable_type'])
    json['assignment_id'] = override.associated_assignment_id
    json
  end
end
