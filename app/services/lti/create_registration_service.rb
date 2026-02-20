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

module Lti
  # Create a new LTI Registration and all of its dependent objects in one place.
  #
  # @param account [Account] the context for operations like binding and overlays
  #
  # @param created_by [User] the user creating the registration
  #
  # @param unified_tool_id [String | nil] The unique identifier for the tool, used for analytics. If not provided, one will be generated.
  #
  # @param registration_params [Hash] Attributes for the new Lti::Registration.
  # ```
  # {
  #   name: "string",
  #   admin_nickname: "string",
  #   description: "string",
  #   vendor: "string",
  # }
  # ```
  #
  # @param configuration_params [Hash] A Schemas::InternalLtiConfiguration object used to create
  # the Lti::ToolConfiguration. If an invalid hash is provided, an ArgumentError will be raised.
  #
  # @param overlay_params [Hash] A Schemas::Lti::Overlay object, stored as `data` in the Lti::Overlay
  # for this Registration and Account. If an invalid hash is provided, an ArgumentError will be raised.
  #
  # @param binding_params [Hash] Attributes for creating the the Lti::RegistrationAccountBinding.
  # ```
  # { workflow_state: "string" }
  # ```
  # @param developer_key_params [Hash] Attributes for creating the DeveloperKey. These take
  # precedence over any inferred attributes from `configuration_params`.
  #
  # @return [Lti::Registration] the newly created registration
  class CreateRegistrationService < ApplicationService
    ALLOWED_DEVELOPER_KEY_PARAMS = %i[name email notes test_cluster_only client_credentials_audience scopes].freeze
    ALLOWED_REGISTRATION_PARAMS = %i[name admin_nickname description vendor].freeze

    attr_reader :account,
                :created_by,
                :unified_tool_id,
                :registration_params,
                :configuration_params,
                :overlay_params,
                :developer_key_params,
                :binding_params

    def initialize(account:,
                   created_by:,
                   registration_params:,
                   configuration_params:,
                   unified_tool_id: nil,
                   overlay_params: {},
                   binding_params: {},
                   developer_key_params: {})
      unless account.is_a?(Account) && created_by.is_a?(User)
        raise ArgumentError, "Please provide a valid account and user"
      end

      @account = account
      @created_by = created_by
      @unified_tool_id = unified_tool_id
      # Ensure we only grab the keys that we actually care about from the hashes.
      # Additional keys are allowed by some of these schemas, but we don't want them, as
      # they could result in a mass assignment vulnerability.
      @registration_params = registration_params.slice(*ALLOWED_REGISTRATION_PARAMS)
      @configuration_params = configuration_params.slice(*Schemas::InternalLtiConfiguration.allowed_base_properties)
      @overlay_params = overlay_params&.slice(*Schemas::Lti::Overlay.allowed_base_properties)
      @binding_params = binding_params&.slice(:workflow_state)
      @developer_key_params = developer_key_params&.slice(*ALLOWED_DEVELOPER_KEY_PARAMS)
      super()
    end

    def call
      Lti::Registration.transaction do
        registration = Lti::Registration.create!(
          **registration_params,
          account:,
          workflow_state: "active",
          created_by:,
          updated_by: created_by
        )

        # TEMPORARY: This is a temporary change. We'll revert this once we disable the old developer keys page.
        # For manual registrations (which always have configuration_params),
        # merge overlay into configuration instead of creating overlay.
        final_config = configuration_params
        scopes = configuration_params[:scopes]

        if overlay_params.present?
          # Validate overlay params before applying
          validation_errors = Schemas::Lti::Overlay.validation_errors(overlay_params, allow_nil: true)
          if validation_errors.present?
            raise ArgumentError, "Invalid overlay parameters: #{validation_errors.to_json}"
          end

          # Manual registrations: merge overlay into config
          # (We know this is a manual registration because we're creating a ToolConfiguration,
          # not linking to an IMS registration)
          merged_config = Lti::Overlay.apply_to(overlay_params, configuration_params, additive: true)
          final_config = merged_config.slice(*Schemas::InternalLtiConfiguration.allowed_base_properties)
          scopes = final_config[:scopes]
        end

        dk = DeveloperKey.create!(
          account: account.site_admin? ? nil : account,
          icon_url: final_config.dig(:launch_settings, :icon_url),
          name: registration_params[:name] || final_config[:title],
          public_jwk: final_config[:public_jwk],
          public_jwk_url: final_config[:public_jwk_url],
          redirect_uris: final_config[:redirect_uris] || [final_config[:target_link_uri]],
          oidc_initiation_url: final_config[:oidc_initiation_url],
          visible: !account.site_admin?,
          scopes:,
          lti_registration: registration,
          workflow_state: "active",
          is_lti_key: true,
          skip_lti_sync: true,
          **developer_key_params
        )

        Lti::ToolConfiguration.create!(
          developer_key: dk,
          lti_registration: registration,
          unified_tool_id:,
          **final_config
        )

        binding = Lti::AccountBindingService.call(account:,
                                                  registration:,
                                                  user: created_by,
                                                  overwrite_created_by: true,
                                                  **binding_params.deep_symbolize_keys)

        if account.feature_enabled?(:lti_registrations_next)
          # If the account binding is "off," make the tool unavailable. Any other binding
          # state (on/allow/etc.) should make the tool available.
          # In this case, the tool default's to the registration's current privacy level.
          enabled = binding[:lti_registration_account_binding].workflow_state != "off"
          registration.new_external_tool(account, current_user: created_by, available: false, enabled:)
        end

        registration
      end
    end
  end
end
