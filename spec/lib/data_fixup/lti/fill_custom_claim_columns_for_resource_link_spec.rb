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

RSpec.describe DataFixup::Lti::FillCustomClaimColumnsForResourceLink do
  let(:tool) { external_tool_model }
  let(:course) { Course.create!(name: 'Course') }
  let(:assignment) { Assignment.create!(course: course, name: 'Assignment') }
  let(:resource_link) do
    Lti::ResourceLink.create!(context_external_tool: tool,
                             context_id: 999,
                             context_type: 'Account',
                             resource_link_id: assignment.lti_context_id)
  end

  describe '.run' do
    it 'set `context_id` and `context_type` according to the related assignment' do
      expect(resource_link.context_id).to eq 999
      expect(resource_link.context_type).to eq 'Account'

      described_class.run

      resource_link.reload

      expect(resource_link.context_id).to eq assignment.id
      expect(resource_link.context_type).to eq 'Assignment'
    end
  end
end
