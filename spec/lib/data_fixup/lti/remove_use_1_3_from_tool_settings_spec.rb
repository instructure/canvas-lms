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

describe DataFixup::Lti::RemoveUse13FromToolSettings do
  subject { DataFixup::Lti::RemoveUse13FromToolSettings.run }

  let(:string_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { "use_1_3" => true }) } }
  let(:symbol_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { use_1_3: true }) } }
  let(:indifferent_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { use_1_3: true }.with_indifferent_access) } }
  let(:existing_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { use_1_3: true, hello: "world" }) } }
  let(:ignored_tool) { external_tool_model.tap { |t| t.update!(settings: { hello: "world" }) } }
  let(:tools) { [string_tool, symbol_tool, indifferent_tool, existing_tool] }

  before do
    ignored_tool
    tools
  end

  it "removes use_1_3 from settings" do
    subject
    tools.each { |t| expect(t.reload.settings.key?(:use_1_3)).to eq false }
  end

  it "ignores 1.1 tools" do
    previous_settings = ignored_tool.settings
    subject
    expect(ignored_tool.reload.settings).to eq previous_settings
  end

  it "does not remove other settings keys" do
    subject
    expect(existing_tool.settings[:hello]).to eq "world"
  end
end
