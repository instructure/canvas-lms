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

  # Returns a JSON representation of an LTI context control.
  #
  # @param context_control [Lti::ContextControl] the context control to serialize
  # @param user [User] the user making the request
  # @param session [Session] the session of the user making the request
  # @param context [Context] the context in which the request is made
  # @param calculated_attrs [Hash] additional data to include in the JSON, can contain:
  #   depth [Integer] the depth of the context control in the hierarchy. used for the UI
  #   display_path [String[]] the names of the accounts in the path. used for the UI
  #   subaccount_count [Integer] the number of subaccounts affected by this control.
  #   course_count [Integer] the number of courses affected by this control.
  #   child_control_count [Integer] the number of child context controls for this control.
  # @param include_users [Boolean] whether to include user details in created_by and updated_by fields
  #
  # @return [Hash] the JSON representation of the context control
  def lti_context_control_json(context_control, user, session, context, calculated_attrs: {}, include_users: false)
    api_json(context_control, user, session, only: JSON_ATTRS).tap do |json|
      json["context_name"] = context_control.context_name
      json["child_control_count"] = calculated_attrs[:child_control_count] || context_control.child_control_count
      json["subaccount_count"] = calculated_attrs[:subaccount_count] || context_control.subaccount_count
      json["course_count"] = calculated_attrs[:course_count] || context_control.course_count
      json["display_path"] = calculated_attrs[:display_path] || context_control.display_path
      json["depth"] = calculated_attrs[:depth] || 0

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
