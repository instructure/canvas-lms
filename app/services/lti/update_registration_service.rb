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

module Lti
  # Update an LTI Registration and all of its dependent objects in one place.
  #
  # @param id [Integer] the ID of the registration to update
  #
  # @param account [Account] the context for operations like binding and overlays
  #
  # @param updated_by [User] the user making the update
  #
  # @param registration_params [Hash] Attributes to update on the Lti::Registration.
  # ```
  # {
  #   name: "string",
  #   admin_nickname: "string",
  #   vendor: "string",
  #   description: "string",
  # }
  # ```
  #
  # @param configuration_params [Hash] A Schemas::InternalLtiConfiguration object used to update
  # the Lti::ToolConfiguration.
  #
  # @param overlay_params [Hash] A Schemas::Lti::Overlay object, stored as `data` in the Lti::Overlay
  # for this Registration and Account.
  #
  # @param binding_params [Hash] Attributes to update on the Lti::RegistrationAccountBinding.
  # ```
  # { workflow_state: "string" }
  # ```
  #
  # @param developer_key_params [Hash] Attributes to update on the DeveloperKey.
  # These take precedence over attributes calculated from registration or configuration.
  #
  # @return [Lti::Registration] the updated registration
  class UpdateRegistrationService < ApplicationService
    def initialize(
      id:,
      account:,
      updated_by:,
      registration_params: {},
      configuration_params: {},
      overlay_params: {},
      binding_params: {},
      developer_key_params: {}
    )
      @id = id
      @account = account
      @updated_by = updated_by
      @registration_params = registration_params
      @configuration_params = configuration_params
      @overlay_params = overlay_params
      @binding_params = binding_params
      @developer_key_params = developer_key_params
      super()
    end

    def call
      Lti::Registration.transaction do
        update_registration!

        update_manual_configuration!
        update_overlay!
        update_developer_key!

        propagate_to_external_tools!
        bind_to_account!

        registration
      end
    end

    private

    def update_registration!
      return unless @registration_params.present?

      registration.update!(@registration_params.merge({ updated_by: @updated_by }))
    end

    def update_overlay!
      return unless @overlay_params.present?

      overlay = Lti::Overlay.find_or_initialize_by(registration:, account: @account)
      overlay.updated_by = @updated_by
      overlay.data = @overlay_params
      overlay.save!
      overlay
    end

    def update_manual_configuration!
      return unless @configuration_params.present?

      # explicitly update external tools later to avoid multiple calls
      Lti::ToolConfiguration.suspend_callbacks(:update_external_tools!) do
        registration.manual_configuration.update!(**@configuration_params)
      end
    end

    def update_developer_key!
      developer_key_update_params = {
        name: @registration_params[:name],
        icon_url: @configuration_params&.dig(:launch_settings, :icon_url),
        oidc_initiation_url: @configuration_params&.dig(:oidc_initiation_url),
        public_jwk: @configuration_params&.dig(:public_jwk),
        public_jwk_url: @configuration_params&.dig(:public_jwk_url),
        redirect_uris: @configuration_params&.dig(:redirect_uris),
        scopes: registration.internal_lti_configuration(include_overlay: true)[:scopes],
        **@developer_key_params,
      }.compact
      return unless developer_key_update_params.present?

      registration.developer_key.update!(developer_key_update_params)
    end

    def bind_to_account!
      workflow_state = @binding_params[:workflow_state]
      return unless workflow_state.present?

      Lti::AccountBindingService.call(
        account: @account,
        registration:,
        workflow_state:,
        user: @updated_by
      )
    end

    def propagate_to_external_tools!
      return unless @configuration_params.present? || @overlay_params.present?

      registration.developer_key.update_external_tools!
    end

    def registration
      @registration ||= Lti::Registration.active.eager_load(:manual_configuration, :developer_key).find(@id)
    end
  end
end
