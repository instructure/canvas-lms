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
#

describe Lti::Concerns::ParentFrame do
  subject { controller.send(:parent_frame_origin) }

  let(:controller_class) do
    Class.new(ApplicationController) do
      include Lti::Concerns::ParentFrame
    end
  end
  let(:controller) { controller_class.new }

  let(:tool) do
    tool = external_tool_model(context: tool_context)
    tool.update! url: "http://mytool.example.com/abc", developer_key: DeveloperKey.create!(internal_service: true)
    tool
  end
  let(:expected_tool_origin) { "http://mytool.example.com" }

  let(:current_pseudonym) do
    user_with_pseudonym
    @pseudonym
  end

  before do
    controller.instance_variable_set(:@current_user, current_pseudonym.user)
    controller.instance_variable_set(:@current_pseudonym, current_pseudonym)
    allow(controller).to receive_messages(parent_frame_context: tool.id.to_s, session: nil)
    allow(ContextExternalTool).to receive(:find_by).with(id: tool.id.to_s).and_return(tool)
  end

  %w[course account].each do |context_type|
    context "when the parent_frame_context tool's context is a #{context_type}" do
      let(:tool_context) { send(:"#{context_type}_model") }

      context "when the user has the read or launch_external_tool permission" do
        before do
          allow(tool.context).to receive(:grants_any_right?).with(
            current_pseudonym.user, anything, :read, :launch_external_tool
          ).and_return(true)
        end

        it { is_expected.to eq(expected_tool_origin) }
      end

      context "when the user does not have the read or launch_external_tool permission" do
        before do
          allow(tool.context).to receive(:grants_any_right?).with(
            current_pseudonym.user, anything, :read, :launch_external_tool
          ).and_return(false)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
