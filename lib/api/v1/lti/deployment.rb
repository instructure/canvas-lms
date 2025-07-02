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

module Api::V1::Lti::Deployment
  include Api::V1::Json
  include Api::V1::Lti::ContextControl

  def lti_deployment_json(deployment, user, session, context, context_controls: nil, context_controls_calculated_attrs: {})
    api_json(deployment, user, session, only: %w[id context_id context_type]).tap do |json|
      json["registration_id"] = deployment.lti_registration_id
      json["deployment_id"] = deployment.deployment_id
      json["context_name"] = deployment.context.name
      json["workflow_state"] = ["deleted", "disabled"].include?(deployment.workflow_state) ? "deleted" : "active"

      if context_controls
        json["context_controls"] = context_controls.map do |context_control|
          calculated_attrs = context_controls_calculated_attrs[context_control.id] || {}
          lti_context_control_json(context_control, user, session, context, calculated_attrs:)
        end
      end
    end
  end
end
