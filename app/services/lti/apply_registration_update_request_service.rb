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
  # Apply a registration update request to an existing LTI Registration,
  # replacing the entire configuration and overlay with new values.
  #
  # @param registration_update_request [Lti::RegistrationUpdateRequest] The request containing the new configuration
  # @param applied_by [User] The user applying the update request
  # @param overlay_data [Hash] Optional overlay data to apply to the registration
  # @param comment [String] Optional comment explaining the reason for applying this update
  #
  # @return [Hash] containing the updated lti_registration
  class ApplyRegistrationUpdateRequestService < ApplicationService
    def initialize(registration_update_request:, applied_by:, overlay_data:, comment: nil)
      @registration_update_request = registration_update_request
      @applied_by = applied_by
      @overlay_data = overlay_data
      @comment = comment
      super()
    end

    def call
      raise ArgumentError, "registration_update_request is required" unless @registration_update_request
      raise ArgumentError, "applied_by is required" unless @applied_by

      registration = @registration_update_request.lti_registration
      raise ArgumentError, "Registration not found" unless registration

      # Only support lti_ims_registration for now
      unless @registration_update_request.lti_ims_registration && registration.ims_registration
        raise ArgumentError, "Only Registration update requests for Dynamic Registrations are currently supported"
      end

      Lti::Registration.transaction do
        # Track all changes in a single history entry
        updated_registration = Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: @applied_by,
          context: @registration_update_request.root_account,
          comment: @comment,
          update_type: "registration_update"
        ) do
          # Replace the entire ims_registration configuration first
          update_ims_registration!(registration.ims_registration)

          # Use UpdateRegistrationService to handle overlay, developer key, and other updates
          # Note: This will create a nested history entry, but that's okay for comprehensive tracking
          Lti::UpdateRegistrationService.call(
            id: registration.id,
            account: @registration_update_request.root_account,
            updated_by: @applied_by,
            registration_params: build_registration_params,
            overlay_params: @overlay_data,
            developer_key_params: build_developer_key_params,
            comment: nil # Skip comment to avoid duplicate entries
          )
        end

        # Mark the update request as applied
        @registration_update_request.update!(accepted_at: Time.current)

        { lti_registration: updated_registration }
      end
    end

    private

    def update_ims_registration!(ims_registration)
      new_config = @registration_update_request.lti_ims_registration

      # Update all the configurable fields from the registration update request
      ims_registration.update!(
        client_name: new_config["client_name"],
        jwks_uri: new_config["jwks_uri"],
        initiate_login_uri: new_config["initiate_login_uri"],
        redirect_uris: new_config["redirect_uris"],
        lti_tool_configuration: new_config["lti_tool_configuration"],
        scopes: new_config["scopes"],
        logo_uri: new_config["logo_uri"],
        client_uri: new_config["client_uri"],
        tos_uri: new_config["tos_uri"],
        policy_uri: new_config["policy_uri"],
        registration_overlay: new_config["registration_overlay"] || {}
      )
    end

    def build_registration_params
      new_config = @registration_update_request.lti_ims_registration
      {
        name: new_config["client_name"]
      }.compact
    end

    def build_developer_key_params
      new_config = @registration_update_request.lti_ims_registration
      {
        name: new_config["client_name"],
        icon_url: new_config["logo_uri"],
        oidc_initiation_url: new_config["initiate_login_uri"],
        public_jwk_url: new_config["jwks_uri"],
        redirect_uris: new_config["redirect_uris"],
        scopes: new_config["scopes"]
      }.compact
    end
  end
end
