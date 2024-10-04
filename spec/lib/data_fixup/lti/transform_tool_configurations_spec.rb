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
require "lti_1_3_tool_configuration_spec_helper"

RSpec.describe DataFixup::Lti::TransformToolConfigurations do
  subject { described_class.run }

  # introduces `settings` (hard-coded JSON LtiConfiguration)
  include_context "lti_1_3_tool_configuration_spec_helper"

  let(:account) { Account.default }
  let(:developer_key) { dev_key_model_1_3(account:) }
  let(:tool_configuration) do
    developer_key.tool_configuration.delete
    # needs to be not transformed yet
    Lti::ToolConfiguration.create!(
      developer_key:,
      settings: settings.merge(public_jwk: tool_config_public_jwk),
      privacy_level: "public"
    )
  end

  before do
    tool_configuration
  end

  it "populates new columns with settings data" do
    expect(tool_configuration.target_link_uri).to be_nil
    subject
    expect(tool_configuration.reload.target_link_uri).to eq(settings["target_link_uri"])
  end

  it "removes data from settings" do
    subject
    expect(tool_configuration.reload[:settings]).to be_blank
  end
end
