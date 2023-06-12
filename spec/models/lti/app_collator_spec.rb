# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../../lti_spec_helper"
require_relative "../../lti_1_3_spec_helper"

module Lti
  describe AppCollator do
    include LtiSpecHelper

    subject { described_class.new(account, mock_reregistration_url_builder) }

    let(:account) { Account.create }
    let(:mock_reregistration_url_builder) { ->(_c, _id) { "mock_url" } }

    context "pagination" do
      it "paginates correctly" do
        3.times do |_|
          tp = create_tool_proxy(context: account, name: "aaa")
          tp.bindings.create(context: account)
        end
        3.times { |_| new_valid_external_tool(account) }

        collection = subject.bookmarked_collection
        per_page = 3
        page1 = collection.paginate(per_page:)
        page2 = collection.paginate(page: page1.next_page, per_page:)
        expect(page1.count).to eq 3
        expect(page2.count).to eq 3
        expect(page1.first).to_not eq page2.first
      end
    end

    describe "#app_definitions" do
      def example_definition(tool, **overrides)
        {
          app_type: tool.class.name,
          context: tool.context_type,
          context_id: tool.context.id,
          app_id: tool.id,
          name: tool.name,
          description: tool.description,
          installed_locally: true,
          has_update: nil,
          enabled: true,
          tool_configuration: nil,
          reregistration_url: nil
        }.merge(overrides)
      end

      it "returns tool_proxy app definitions" do
        tool_proxy = create_tool_proxy(context: account)
        tool_proxy.bindings.create(context: account)
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a
        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq(example_definition(tool_proxy, lti_version: "2.0"))
      end

      it "returns an external tool app definition" do
        external_tool = new_valid_external_tool(account)
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq(example_definition(external_tool,
                                                    lti_version: "1.1",
                                                    deployment_id: external_tool.deployment_id,
                                                    editor_button_settings: external_tool.editor_button))
      end

      it "returns an external tool app definition as 1.3 tool" do
        external_tool = new_valid_external_tool(account)
        external_tool.use_1_3 = true
        external_tool.save!
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq(example_definition(external_tool,
                                                    lti_version: "1.3",
                                                    deployment_id: external_tool.deployment_id,
                                                    editor_button_settings: external_tool.editor_button))
      end

      it "returns definition with rce_favorite when editor_button placement is present" do
        external_tool = new_valid_external_tool(account)
        external_tool.editor_button = { icon_url: "http://example.com/editor_button" }
        external_tool.save!
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq(example_definition(external_tool,
                                                    lti_version: "1.1",
                                                    deployment_id: external_tool.deployment_id,
                                                    editor_button_settings: external_tool.editor_button,
                                                    is_rce_favorite: false))
      end

      it "returns an external tool and a tool proxy" do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        new_valid_external_tool(account)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 2
        external_tool = definitions.find { |d| d[:app_type] == "ContextExternalTool" }
        tool_proxy = definitions.find { |d| d[:app_type] == "Lti::ToolProxy" }
        expect(tool_proxy).to_not be_nil
        expect(external_tool).to_not be_nil
      end

      it "has check_for_update set to false" do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        new_valid_external_tool(account)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 2
        external_tool = definitions.find { |d| d[:app_type] == "ContextExternalTool" }
        tool_proxy = definitions.find { |d| d[:app_type] == "Lti::ToolProxy" }
        expect(external_tool[:reregistration_url]).to be_nil
        expect(tool_proxy[:reregistration_url]).to be_nil
      end

      it "has reregistartion set to true for tool proxies if the feature flag is enabled" do
        account.root_account.enable_feature!(:lti2_rereg)
        tool_proxy = create_tool_proxy
        tool_proxy.bindings.create(context: account)
        allow_any_instance_of(ToolProxy).to receive(:reregistration_message_handler).and_return(true)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition[:reregistration_url]).to eq "mock_url"
      end

      it "has_update set to false for tool proxies without an update_payload" do
        account.root_account.enable_feature!(:lti2_rereg)

        tool_proxy = create_tool_proxy(context: account)
        tool_proxy.bindings.create(context: account)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a
        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq(example_definition(tool_proxy,
                                                    has_update: false,
                                                    lti_version: "2.0"))
      end

      it "has_update set to true for tool proxies with an update_payload" do
        account.root_account.enable_feature!(:lti2_rereg)

        tool_proxy = create_tool_proxy(context: account)
        tool_proxy.bindings.create(context: account)
        tool_proxy.update_payload = { one: 2 }
        tool_proxy.save!

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a
        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq(example_definition(tool_proxy,
                                                    has_update: true,
                                                    lti_version: "2.0"))
      end

      it "has reregistartion set to false for external_tools if the feature flag is enabled" do
        account.root_account.enable_feature!(:lti2_rereg)
        new_valid_external_tool(account)
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition[:reregistration_url]).to be_nil
      end
    end
  end
end
