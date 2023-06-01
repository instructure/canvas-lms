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
    @dev_key = factory_with_protected_attributes(DeveloperKey, dev_key_valid_attributes(opts).merge(opts))
  end

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
    opts = dev_key_valid_attributes({ is_lti_key: true,
                                      public_jwk_url: "http://example.com/jwks" }.merge(opts))

    tool_configuration_params = {
      settings: opts[:settings].presence || JSON.parse(Rails.root.join(LTI_1_3_CONFIG_PATH).read)
    }.with_indifferent_access
    Lti::ToolConfiguration.create_tool_config_and_key!(opts[:account], tool_configuration_params)
    DeveloperKey.last.update!(opts)
    DeveloperKey.last
  end
end
