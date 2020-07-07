#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../../spec_helper'

describe DataFixup::UpdateMasteryConnectToolConfig do
  before :once do
    course_model

  end

  describe 'context_external_tool' do
    it 'contains the correct settings after the fixup' do
      tool = external_tool_model(context: @course, opts: { domain: 'app.masteryconnect.com' })
      DataFixup::UpdateMasteryConnectToolConfig.run
      tool.reload
      expect(tool.settings).to include("submission_type_selection")
    end

    it 'does not modify settings if not mastery connect tool' do
      tool = external_tool_model(context: @course, opts: { domain: 'some.other.tool.com' })
      DataFixup::UpdateMasteryConnectToolConfig.run
      tool.reload
      expect(tool.settings).not_to include("submission_type_selection")
    end

    it 'does not modify settings if placement already exists' do
      settings = {
        "submission_type_selection" => {
          foo: 'bar'
        }
      }
      tool = external_tool_model(context: @course, opts: { domain: 'app.masteryconnect.com', settings: settings })
      DataFixup::UpdateMasteryConnectToolConfig.run
      tool.reload
      expect(tool.settings).to eq(settings)
    end

    it 'updates multiple installs of the mastery connect tool' do
      tool1 = external_tool_model(context: @course, opts: { domain: 'app.masteryconnect.com' })
      tool2 = external_tool_model(context: @course, opts: { domain: 'app.masteryconnect.com' })
      DataFixup::UpdateMasteryConnectToolConfig.run
      tool1.reload
      tool2.reload
      expect(tool1.settings).to include("submission_type_selection")
      expect(tool2.settings).to include("submission_type_selection")
    end
  end

end