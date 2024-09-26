# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
  LTI_1_3_CONFIG_PATH = "spec/fixtures/lti/lti-1.3-tool-config.json"

  def dev_key_model(opts = {})
    @dev_key = DeveloperKey.create!(dev_key_valid_attributes(opts).merge(opts))
  end
  alias_method :developer_key_model, :dev_key_model

  def dev_key_valid_attributes(opts = {})
    account = opts[:account].presence
    name = opts[:name] || "A Random Dev Key"
    email = opts[:email] || "test@example.com"

    {
      name:,
      email:,
      account:
    }
  end

  def dev_key_model_1_3(opts = {})
    opts[:account] ||= Account.default
    opts = dev_key_valid_attributes({ is_lti_key: true,
                                      public_jwk_url: "http://example.com/jwks" }.merge(opts))

    tool_configuration_params = {
      settings: opts[:settings].presence || JSON.parse(Rails.root.join(LTI_1_3_CONFIG_PATH).read)
    }.with_indifferent_access
    Lti::ToolConfiguration.create_tool_config_and_key!(opts[:account], tool_configuration_params)

    # special case to remove the account if the account was site admin; when the dev
    # key is created, if the account is site admin, the account on the dev key will be set
    # to nil. We need to keep it that way and not stomp over it with a new account value here.
    opts[:account] = nil if opts[:account].site_admin?

    DeveloperKey.last.update!(opts)
    DeveloperKey.last
  end

  def dev_key_model_dyn_reg(opts = {})
    key = dev_key_model_1_3(opts)
    registration(key)
    key
  end

  def registration(key)
    redirect_uris = ["http://example.com"]
    initiate_login_uri = "http://example.com/login"
    client_name = "Example Tool"
    jwks_uri = "http://example.com/jwks"
    logo_uri = "http://example.com/logo.png"
    client_uri = "http://example.com/"
    tos_uri = "http://example.com/tos"
    policy_uri = "http://example.com/policy"
    lti_tool_configuration = {
      domain: "example.com",
      messages: [
        {
          type: "LtiResourceLinkRequest",
          target_link_uri: "http://example.com/launch",
          placements: ["course_navigation"]
        }
      ],
      claims: []
    }
    scopes = []
    registration = Lti::IMS::Registration.new({
      redirect_uris:,
      initiate_login_uri:,
      client_name:,
      jwks_uri:,
      logo_uri:,
      client_uri:,
      tos_uri:,
      policy_uri:,
      lti_tool_configuration:,
      scopes:
    }.compact)
    registration.developer_key = key
    registration
  end
end
