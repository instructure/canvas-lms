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

module Api::V1::Lti::Registration
  include Api::V1::Json
  include Api::V1::User
  include Api::V1::Lti::RegistrationAccountBinding

  JSON_ATTRS = %w[
    id account_id root_account_id internal_service vendor name admin_nickname workflow_state created_at updated_at
  ].freeze

  # Serializes a list of LTI registrations.
  # @param includes [Array<Symbol>] Accepted values: [:configuration, :account_binding]
  def lti_registrations_json(registrations, user, session, context, includes: [])
    if includes.include?(:account_binding)
      Lti::Registration.preload_account_bindings(registrations, context)
    end

    registrations.map { |r| lti_registration_json(r, user, session, context, includes:) }
  end

  # Serializes a single LTI registration.
  # @param includes [Array<Symbol>] Accepted values: [:configuration, :account_binding]
  def lti_registration_json(registration, user, session, context, includes: [])
    includes = includes.map(&:to_sym)

    api_json(registration, user, session, only: JSON_ATTRS).tap do |json|
      json["inherited"] = registration.inherited_for?(context)
      json["lti_version"] = registration.lti_version
      json["icon_url"] = registration.icon_url
      json["dynamic_registration"] = true if registration.dynamic_registration?
      json["developer_key_id"] = registration.developer_key&.global_id

      if registration.created_by.present?
        json["created_by"] = user_json(registration.created_by, user, session, [], context)
      end
      if registration.updated_by.present?
        json["updated_by"] = user_json(registration.updated_by, user, session, [], context)
      end
      if includes.include?(:configuration)
        json["configuration"] = registration.configuration
      end

      if includes.include?(:account_binding) && (acct_binding = registration.account_binding_for(context))
        json["account_binding"] = lti_registration_account_binding_json(acct_binding, user, session, context)
      end
    end
  end
end
