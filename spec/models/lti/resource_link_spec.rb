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

require_relative '../../spec_helper'

RSpec.describe Lti::ResourceLink, type: :model do
  let(:tool) { external_tool_model }
  let(:resource_link) { Lti::ResourceLink.create!(context_external_tool: tool) }

  context 'when validating' do
    it 'sets the "resource_link_id" if it is not specified' do
      expect(resource_link.resource_link_id).not_to be_blank
    end

    it 'sets the "context_external_tool"' do
      expect(resource_link.original_context_external_tool).to eq tool
    end
  end

  context 'after saving' do
    it 'sets the root_account using context_external_tool' do
      expect(resource_link.root_account).to eq tool.root_account
    end

    it 'leaves root_account_id blank if tool has none' do
      tool.root_account = nil
      link = Lti::ResourceLink.create!(context_external_tool: tool)
      expect(link.root_account).to be_nil
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
end
