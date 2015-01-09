#
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
require File.expand_path(File.dirname(__FILE__) + '/../../lti_spec_helper.rb')

module Lti
  describe AppCollator do
    subject { described_class.new(account) }
    let (:account) { Account.create }

    context 'pagination' do
      it 'paginates correctly' do
        3.times do |_|
          tp = create_tool_proxy(account: account)
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
        tool_proxy = create_tool_proxy
        tool_proxy.bindings.create(context: account)

        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq({
                                   app_type: tool_proxy.class.name,
                                   app_id: tool_proxy.id,
                                   name: tool_proxy.name,
                                   description: tool_proxy.description,
                                   installed_locally: true,
                                   enabled: true
                                 })

      end

      it 'returns an external tool app definition' do
        external_tool = new_valid_external_tool(account)
        tools_collection = subject.bookmarked_collection.paginate(per_page: 100).to_a

        definitions = subject.app_definitions(tools_collection)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq( {
                                    app_type: external_tool.class.name,
                                    app_id: external_tool.id,
                                    name: external_tool.name,
                                    description: external_tool.description,
                                    installed_locally: true,
                                    enabled: true
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

    end

  end
end