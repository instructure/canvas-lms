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

module Api::V1::Lti::RegistrationUpdateRequest
  include Api::V1::Json
  include Api::V1::User

  JSON_ATTRS = %w[
    id
    root_account_id
    lti_registration_id
    uuid
    reinstall
    tool_initiated
    comment
    created_at
    updated_at
    accepted_at
    rejected_at
  ].freeze

  # Serializes a list of LTI registration update requests.
  # @param includes [Array<Symbol>] Accepted values: [:configuration, :lti_registration]
  def lti_registration_update_requests_json(update_requests, user, session, context)
    update_requests.map do |request|
      lti_registration_update_request_json(request, user, session, context)
    end
  end

  # Serializes a single LTI registration update request.
  # @param includes [Array<Symbol>] Accepted values: [:configuration, :lti_registration]
  #
  # @return [Hash] JSON representation of the LTI registration update request.
  def lti_registration_update_request_json(update_request, user, session, context)
    api_json(update_request, user, session, only: JSON_ATTRS).tap do |json|
      json["status"] = if update_request.applied?
                         "applied"
                       elsif update_request.rejected?
                         "rejected"
                       else
                         "pending"
                       end

      if update_request.created_by.present?
        json["created_by"] = render_user_or_instructure(update_request.created_by, user, session, context)
      end

      if update_request.updated_by.present?
        json["updated_by"] = render_user_or_instructure(update_request.updated_by, user, session, context)
      end
    end
  end

  private

  # Renders a user JSON or returns "Instructure" if the user has site admin read access
  def render_user_or_instructure(target_user, current_user, session, context)
    if Account.site_admin.grants_right?(target_user, session, :read)
      "Instructure"
    else
      user_json(target_user, current_user, session, [], context, nil, ["pseudonym"])
    end
  end
end
