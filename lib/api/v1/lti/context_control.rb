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

module Api::V1::Lti::ContextControl
  include Api::V1::Json
  include Api::V1::User

  JSON_ATTRS = %w[
    id account_id course_id registration_id deployment_id workflow_state created_at updated_at available path
  ].freeze

  def lti_context_control_json(context_control, user, session, context, depth: nil, display_path: nil, include_users: false)
    api_json(context_control, user, session, only: JSON_ATTRS).tap do |json|
      json["context_name"] = context_control.context_name
      json["display_path"] = display_path || context_control.path_names
      json["depth"] = depth || 0

      json["created_by"] = nil
      if include_users && context_control.created_by.present?
        json["created_by"] = user_json(context_control.created_by, user, session, [], context, nil, ["pseudonym"])
      end
      json["updated_by"] = nil
      if include_users && context_control.updated_by.present?
        json["updated_by"] = user_json(context_control.updated_by, user, session, [], context, nil, ["pseudonym"])
      end
    end
  end
end
