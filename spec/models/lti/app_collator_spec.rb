# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency "lti/app_collator"

module Lti
  describe AppCollator, :include_lti_spec_helpers do

    subject { described_class.new(account, mock_reregistration_url_builder)}
    let(:account) { Account.create }
    let(:mock_reregistration_url_builder) { -> (_c, _id) {"mock_url"} }

    context 'pagination' do
      it 'paginates correctly' do
        3.times do |_|
          tp = create_tool_proxy(account: account, name: 'aaa')
          tp.bindings.create(context: account)
        end
        3.times { |_| new_valid_external_tool(account) }

        collection = subject.bookmarked_collection
        per_page = 3
        page1 = collection.paginate(per_page: per_page)
        page2 = collection.paginate(page: page1.next_page, per_page: per_page)
        expect(page1.count).to eq 3
        expect(page2.count).to eq 3
        expect(page1.first).to_not eq page2.first
      end
    end

    describe "#app_definitions" do

      it 'returns tool_proxy app definitions' do
        tool_proxy = create_tool_proxy(context: account)
        tool_proxy.bindings.create(context: account)
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a
        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                   app_type: tool_proxy.class.name,
                                   :context => tool_proxy.context_type,
                                   :context_id => account.id,
                                   app_id: tool_proxy.id,
                                   name: tool_proxy.name,
                                   description: tool_proxy.description,
                                   installed_locally: true,
                                   has_update: nil,
                                   enabled: true,
                                   tool_configuration: nil,
                                   reregistration_url: nil
                                 })

      end

      it 'returns an external tool app definition' do
        external_tool = new_valid_external_tool(account)
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                    app_type: external_tool.class.name,
                                    app_id: external_tool.id,
                                    :context => external_tool.context_type,
                                    :context_id => account.id,
                                    name: external_tool.name,
                                    description: external_tool.description,
                                    installed_locally: true,
                                    has_update: nil,
                                    enabled: true,
                                    tool_configuration: nil,
                                    reregistration_url: nil
                                  })
      end

      it 'returns an external tool and a tool proxy' do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        new_valid_external_tool(account)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 2
        external_tool = definitions.find { |d| d[:app_type] == 'ContextExternalTool' }
        tool_proxy = definitions.find { |d| d[:app_type] == 'Lti::ToolProxy' }
        expect(tool_proxy).to_not be nil
        expect(external_tool).to_not be nil
      end

      it 'has check_for_update set to false' do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        new_valid_external_tool(account)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 2
        external_tool = definitions.find { |d| d[:app_type] == 'ContextExternalTool' }
        tool_proxy = definitions.find { |d| d[:app_type] == 'Lti::ToolProxy' }
        expect(external_tool[:reregistration_url]).to eq nil
        expect(tool_proxy[:reregistration_url]).to eq nil
      end

      it 'has reregistartion set to true for tool proxies if the feature flag is enabled' do
        account.root_account.enable_feature!(:lti2_rereg)
        tool_proxy = create_tool_proxy
        tool_proxy.bindings.create(context: account)
        ToolProxy.any_instance.stubs(:reregistration_message_handler).returns(true)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition[:reregistration_url]).to eq 'mock_url'
      end

      it 'has_update set to false for tool proxies without an update_payload' do
        account.root_account.enable_feature!(:lti2_rereg)

        tool_proxy = create_tool_proxy(context: account)
        tool_proxy.bindings.create(context: account)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a
        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                     app_type: tool_proxy.class.name,
                                     :context => tool_proxy.context_type,
                                     :context_id => account.id,
                                     app_id: tool_proxy.id,
                                     name: tool_proxy.name,
                                     description: tool_proxy.description,
                                     installed_locally: true,
                                     has_update: false,
                                     enabled: true,
                                     tool_configuration: nil,
                                     reregistration_url: nil
                                 })
      end

      it 'has_update set to true for tool proxies with an update_payload' do
        account.root_account.enable_feature!(:lti2_rereg)

        tool_proxy = create_tool_proxy(context: account)
        tool_proxy.bindings.create(context: account)
        tool_proxy.update_payload = {one: 2}
        tool_proxy.save!

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a
        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                     app_type: tool_proxy.class.name,
                                     :context => tool_proxy.context_type,
                                     :context_id => account.id,
                                     app_id: tool_proxy.id,
                                     name: tool_proxy.name,
                                     description: tool_proxy.description,
                                     installed_locally: true,
                                     has_update: true,
                                     enabled: true,
                                     tool_configuration: nil,
                                     reregistration_url: nil
                                 })
      end

      it 'has reregistartion set to false for external_tools if the feature flag is enabled' do
        account.root_account.enable_feature!(:lti2_rereg)
        new_valid_external_tool(account)
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition[:reregistration_url]).to eq nil
      end

    end

  end
end
