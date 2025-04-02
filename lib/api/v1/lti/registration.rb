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
  include Api::V1::Lti::Overlay
  include Api::V1::Lti::OverlayVersion
  include Api::V1::Lti::RegistrationAccountBinding

  JSON_ATTRS = %w[
    id account_id root_account_id internal_service vendor name admin_nickname workflow_state created_at updated_at description
  ].freeze

  OVERLAY_VERSION_DEFAULT_LIMIT = 5

  # Serializes a list of LTI registrations.
  # If you are using this method, you must provide the :account_binding and :overlay preloads, otherwise
  # they will not be included in the response, to avoid unnecessary database queries.
  # @param includes [Array<Symbol>] Accepted values: [:configuration, :account_binding]
  # @param preloads [Hash] Preloaded associations, indexed by global registration id. { "1" => { account_binding: ..., overlay: } }
  def lti_registrations_json(registrations, user, session, context, includes: [], preloads: {})
    registrations.map do |r|
      account_binding = preloads.dig(r.global_id, :account_binding)
      overlay = preloads.dig(r.global_id, :overlay)
      lti_registration_json(r, user, session, context, includes:, account_binding:, overlay:)
    end
  end

  # Serializes a single LTI registration.
  # If your includes array includes :account_binding or :overlay, you must provide the account_binding and overlay
  # parameters, otherwise they will not be included, to avoid unnecessary database queries.
  # @param includes [Array<Symbol>] Accepted values: [:configuration, :account_binding, :overlay, :overlay_versions]
  # @param account_binding [Lti::RegistrationAccountBinding] Preloaded account binding to include in the response.
  # @param overlay [Lti::Overlay] Preloaded overlay to include in the response.
  def lti_registration_json(registration, user, session, context, includes: [], account_binding: nil, overlay: nil)
    includes = includes.map(&:to_sym)

    api_json(registration, user, session, only: JSON_ATTRS).tap do |json|
      json["inherited"] = registration.inherited_for?(context)
      json["lti_version"] = registration.lti_version
      json["icon_url"] = registration.icon_url
      json["dynamic_registration"] = true if registration.dynamic_registration?
      json["developer_key_id"] = registration.developer_key&.global_id
      json["ims_registration_id"] = registration.ims_registration&.id
      json["manual_configuration_id"] = registration.manual_configuration&.id

      if registration.site_admin?
        json["created_by"] = "Instructure"
      elsif registration.created_by.present?
        json["created_by"] = user_json(registration.created_by, user, session, [], context, nil, ["pseudonym"])
      end

      if registration.site_admin?
        json["updated_by"] = "Instructure"
      elsif registration.updated_by.present?
        json["updated_by"] = user_json(registration.updated_by, user, session, [], context, nil, ["pseudonym"])
      end

      if includes.include?(:configuration)
        json["configuration"] = registration.internal_lti_configuration(include_overlay: false)
      end

      if includes.include?(:overlaid_configuration)
        json["overlaid_configuration"] = registration.internal_lti_configuration(context:)
      end

      if includes.include?(:overlaid_legacy_configuration)
        json["overlaid_legacy_configuration"] = registration.canvas_configuration
      end

      if includes.include?(:account_binding) && account_binding.present?
        json["account_binding"] = lti_registration_account_binding_json(account_binding, user, session, context)
      end

      if includes.include?(:overlay) && overlay.present?
        json["overlay"] = lti_overlay_json(overlay, user, session, context)
        if includes.include?(:overlay_versions)
          versions = Lti::OverlayVersion.where(lti_overlay: overlay).order(created_at: :desc).limit(OVERLAY_VERSION_DEFAULT_LIMIT)
          json["overlay"]["versions"] = lti_overlay_versions_json(versions, user, session, context)
        end
      end
    end
  end
end
