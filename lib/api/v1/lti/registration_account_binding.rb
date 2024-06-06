# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Api::V1::Lti::RegistrationAccountBinding
  include Api::V1::Json
  include Api::V1::User

  JSON_ATTRS = %w[
    id account_id root_account_id registration_id workflow_state created_at updated_at
  ].freeze

  def lti_registration_account_binding_json(account_binding, user, session, context)
    api_json(account_binding, user, session, only: JSON_ATTRS).tap do |json|
      if account_binding.created_by.present?
        json["created_by"] = user_json(account_binding.created_by, user, session, [], context)
      end

      if account_binding.updated_by.present?
        json["updated_by"] = user_json(account_binding.updated_by, user, session, [], context)
      end
    end
  end
end
