# frozen_string_literal: true

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
#

require 'spec_helper'

RSpec.describe DataFixup::Lti::FillLookupUuidAndResourceLinkUuidColumns do
  let(:tool) { external_tool_model }
  let(:course) { Course.create!(name: 'Course') }
  let(:assignment) { Assignment.create!(course: course, name: 'Assignment') }

  describe '.run' do
    it 'set `lookup_uuid` and `resource_link_uuid` according to the related fields' do
      rl_1 = Lti::ResourceLink.create!(context_external_tool: tool, context: course)
      rl_1.lookup_uuid = nil
      rl_1.resource_link_uuid = nil
      rl_1.save(validate: false)

      rl_2 = Lti::ResourceLink.create!(context_external_tool: tool, context: assignment)
      rl_2.lookup_id = 'foo'
      rl_2.lookup_uuid = nil
      rl_2.resource_link_uuid = nil
      rl_2.save(validate: false)

      rl_3 = Lti::ResourceLink.create!(context_external_tool: tool, context: assignment)
      rl_3.lookup_uuid = nil
      rl_3.resource_link_uuid = nil
      rl_3.resource_link_id = 'd5f77d1-761-4ce-9c1f-525ed24824'
      rl_3.save(validate: false)

      described_class.run

      rl_1.reload

      expect(rl_1.lookup_uuid).to eq rl_1.lookup_id
      expect(rl_1.resource_link_uuid).to eq rl_1.resource_link_id

      rl_2.reload

      expect(rl_2.lookup_id).to_not eq 'foo'
      expect(rl_2.lookup_uuid).to eq rl_2.lookup_id
      expect(rl_2.resource_link_uuid).to eq rl_2.resource_link_id

      rl_3.reload

      expect(rl_3.resource_link_id).to_not eq 'd5f77d1-761-4ce-9c1f-525ed24824'
      expect(rl_3.lookup_uuid).to eq rl_3.lookup_id
      expect(rl_3.resource_link_uuid).to eq rl_3.resource_link_id
    end
  end
end
