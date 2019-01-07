#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper'

RSpec.describe Lti::Ims::LineItemsSerializer do
  let(:resource_link) { resource_link_model(overrides: {resource_link_id: assignment.lti_context_id}) }
  let_once(:course) { course_model }
  let(:tool) {
    ContextExternalTool.create!(
      context: course,
      consumer_key: 'key',
      shared_secret: 'secret',
      name: 'wrong tool',
      url: 'http://www.wrong_tool.com/launch',
      developer_key: DeveloperKey.create!,
      settings: { use_1_3: true },
      workflow_state: 'public'
    )
  }
  let(:assignment) do
    opts = {
      course: course,
      submission_types: 'external_tool',
      external_tool_tag_attributes: {
        url: tool.url,
        content_type: 'context_external_tool',
        content_id: tool.id
      }
    }
    assignment_model(opts)
  end
  let(:line_item_id) do
    Rails.application.routes.url_helpers.lti_line_item_edit_path(
      course_id: 1,
      id: 1
    )
  end
  let(:line_item) do
    line_item_model(
      assignment: assignment,
      resource_link: resource_link,
      label: 'label',
      tag: 'tag',
      score_maximum: 60,
      resource_id: 'resource_id'
    )
  end

  describe '#as_json' do
    it 'properly formats the line item hash' do
      expect(described_class.new(line_item, line_item_id).as_json).to eq(
        {
          id: line_item_id,
          scoreMaximum: line_item.score_maximum,
          label: line_item.label,
          resourceId: line_item.resource_id,
          tag: line_item.tag,
          resourceLinkId: line_item.resource_link&.resource_link_id
        }
      )
    end

    it 'does not incude values that are nil' do
      line_item.update_attributes!(resource_link: nil, tag: nil)
      expect(described_class.new(line_item, line_item_id).as_json).to eq(
        {
          id: line_item_id,
          scoreMaximum: line_item.score_maximum,
          label: line_item.label,
          resourceId: line_item.resource_id
        }
      )
    end
  end
end
