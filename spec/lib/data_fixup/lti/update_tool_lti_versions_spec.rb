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

describe DataFixup::Lti::UpdateToolLtiVersions do
  subject { DataFixup::Lti::UpdateToolLtiVersions.run }

  let(:string_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { use_1_3: true }) } }
  let(:symbol_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { use_1_3: true }) } }
  let(:indifferent_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { use_1_3: true }.with_indifferent_access) } }
  let(:existing_tool) { external_tool_1_3_model.tap { |t| t.update!(settings: { use_1_3: true, hello: "world" }) } }
  let(:tools) { [string_tool, symbol_tool, indifferent_tool, existing_tool] }

  before do
    tools.each { |t| t.update!(lti_version: "1.1") }
  end

  it "updates lti_version" do
    subject
    tools.each { |t| expect(t.reload.lti_version).to eq "1.3" }
  end
end
