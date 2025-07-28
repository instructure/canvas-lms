# frozen_string_literal: true

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

module Factories
  DEFAULT_DEV_KEY_PARAMS = {
    is_lti_key: true,
    public_jwk_url: "http://example.com/jwks",
    name: "A Random Dev Key",
    email: "test@example.com",
    scopes: []
  }.with_indifferent_access.freeze
  DEFAULT_REGISTRATION_PARAMS = {
    name: "Test Registration",
    admin_nickname: "Test Admin",
    description: "A test LTI registration",
    vendor: "Test Vendor"
  }.with_indifferent_access.freeze
  DEFAULT_OVERLAY_PARAMS = {}.with_indifferent_access.freeze
  DEFAULT_BINDING_PARAMS = {}.with_indifferent_access.freeze

  def lti_registration_model(**params)
    params ||= {}
    params[:created_by] ||= user_model
    params[:updated_by] ||= params[:created_by]
    params[:account] ||= account_model
    params[:name] ||= "Test Registration"
    include_binding = params.delete(:bound)
    overlay_data = params.delete(:overlay)
    @lti_registration = Lti::Registration.create!(params)
    if include_binding
      lti_registration_account_binding_model(registration: @lti_registration, account: @lti_registration.account, workflow_state: :on)
    end
    if overlay_data.present?
      lti_overlay_model(registration: @lti_registration, account: @lti_registration.account, data: overlay_data, updated_by: @lti_registration.created_by)
    end
    @lti_registration
  end

  def lti_registration_with_tool(account: nil,
                                 created_by: nil,
                                 developer_key_params: {},
                                 registration_params: {},
                                 configuration_params: {},
                                 overlay_params: {},
                                 binding_params: {})
    account ||= account_model
    created_by ||= user_model

    registration_params = DEFAULT_REGISTRATION_PARAMS.deep_merge(registration_params)
    developer_key_params = DEFAULT_DEV_KEY_PARAMS.deep_merge(developer_key_params)
    configuration_params = Factories::LTI_TOOL_CONFIGURATION_BASE_ATTRS.with_indifferent_access
                                                                       .deep_merge(configuration_params)
    overlay_params = DEFAULT_OVERLAY_PARAMS.deep_merge(overlay_params)
    binding_params = DEFAULT_BINDING_PARAMS.deep_merge(binding_params)

    registration = Lti::CreateRegistrationService.call(
      account:,
      created_by:,
      registration_params:,
      configuration_params:,
      overlay_params:,
      binding_params:,
      developer_key_params:
    )

    # The registration service always makes the tool unavailable by default.
    registration&.deployments&.first&.context_controls&.first&.update!(available: true)

    registration
  end
end
