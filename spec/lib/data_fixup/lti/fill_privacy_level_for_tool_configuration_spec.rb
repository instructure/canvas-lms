# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require "lti_1_3_tool_configuration_spec_helper"

describe DataFixup::Lti::FillPrivacyLevelForToolConfiguration do
  subject { DataFixup::Lti::FillPrivacyLevelForToolConfiguration.run }

  include_context "lti_1_3_tool_configuration_spec_helper"

  let(:account) { account_model }
  let(:developer_key) { DeveloperKey.create!(account: account) }

  before do
    tool_configuration.update! privacy_level: nil
  end

  it "sets privacy_level column from provided value" do
    subject
    expect(tool_configuration.reload[:privacy_level]).to eq tool_configuration.send(:canvas_extensions)["privacy_level"]
  end
end
