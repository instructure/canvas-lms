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
  def dev_key_model(opts = {})
    @dev_key = DeveloperKey.create!(dev_key_valid_attributes(opts).merge(opts))
  end
  alias_method :developer_key_model, :dev_key_model

  def dev_key_valid_attributes(opts = {})
    account = opts[:account].presence
    name = opts[:name] || "A Random Dev Key"
    email = opts[:email] || "test@example.com"
    scopes = opts[:scopes] || []

    {
      name:,
      email:,
      account:,
      scopes:
    }
  end

  def lti_developer_key_model(opts = {})
    opts[:account] ||= Account.default
    opts[:account] = nil if opts[:account].site_admin?
    opts = dev_key_valid_attributes(opts).merge({ is_lti_key: true, public_jwk_url: "http://example.com/jwks" })
    DeveloperKey.create!(opts)
  end
  alias_method :dev_key_model_1_3, :lti_developer_key_model

  def dev_key_model_dyn_reg(opts = {})
    key = lti_developer_key_model(opts)
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
    Lti::IMS::Registration.create!({
      redirect_uris:,
      initiate_login_uri:,
      client_name:,
      jwks_uri:,
      logo_uri:,
      client_uri:,
      tos_uri:,
      policy_uri:,
      lti_tool_configuration:,
      scopes:,
      developer_key: key,
      lti_registration: key.lti_registration
    }.compact)
  end
end
