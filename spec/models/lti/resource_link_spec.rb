# frozen_string_literal: true

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
#

require 'spec_helper'

RSpec.describe Lti::ResourceLink, type: :model do
  let(:tool) { external_tool_model }
  let(:course) { Course.create!(name: 'Course') }
  let(:assignment) { Assignment.create!(course: course, name: 'Assignment') }
  let(:resource_link) do
    Lti::ResourceLink.create!(context_external_tool: tool, context: assignment)
  end

  context "relationships" do
    it { is_expected.to belong_to(:context) }
    it { is_expected.to belong_to(:root_account) }

    it { is_expected.to have_many(:line_items) }
  end

  context 'when validating' do
    it 'sets the "context_id" if it is not specified' do
      expect(resource_link.context_id).not_to be_blank
    end

    it 'sets the "context_type" if it is not specified' do
      expect(resource_link.context_type).not_to be_blank
    end

    it 'sets the "lookup_uuid" if it is not specified' do
      expect(resource_link.lookup_uuid).not_to be_blank
    end

    it 'sets the "resource_link_uuid" if it is not specified' do
      expect(resource_link.resource_link_uuid).not_to be_blank
    end

    it 'sets the "context_external_tool"' do
      expect(resource_link.original_context_external_tool).to eq tool
    end

    it '`lookup_uuid` should be unique scoped to `context`' do
      expect(resource_link).to validate_uniqueness_of(:lookup_uuid).scoped_to(:context_id, :context_type).ignoring_case_sensitivity
    end
  end

  context 'after saving' do
    it 'sets the root_account using context_external_tool' do
      expect(resource_link.root_account).to eq tool.root_account
    end
  end

  describe "#context_external_tool" do
    it 'raises an error' do
      expect { resource_link.context_external_tool }.to raise_error 'Use Lti::ResourceLink#current_external_tool to lookup associated tool'
    end
  end

  describe "#current_external_tool" do
    subject { resource_link.current_external_tool(context) }

    context 'when the original tool has been deleted' do
      let(:context) { tool.context }

      before do
        tool.destroy!
        second_tool
      end

      context 'when a matching tool exists in the specified context' do
        let(:second_tool) { external_tool_model(context: context) }

        it { is_expected.to eq second_tool }
      end

      context 'when a matching tool exists up the context account chain' do
        let(:second_tool) { external_tool_model(context: context.root_account) }

        it { is_expected.to eq second_tool }
      end

      context 'when a matching tool does not exist' do
        let(:second_tool) { nil }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '.create_with' do
    context 'without `context` and `tool`' do
      it 'do not create a resource link' do
        expect(described_class.create_with(nil, nil)).to be_nil
      end
    end

    context 'with `context` and `tool`' do
      let(:custom) do
        {
          referer_id: 123,
          referer_name: 'Sample 123'
        }
      end

      it 'create resource links' do
        resource_link_1 = described_class.create_with(course, tool, custom)
        resource_link_2 = described_class.create_with(course, tool, custom)

        expect(course.lti_resource_links.count).to eq 2
        expect(course.lti_resource_links.first).to eq resource_link_1
        expect(course.lti_resource_links.last).to eq resource_link_2
      end
    end
  end
end
