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

module Lti
  describe AppLaunchCollator do
    let (:account) { Account.create }
    let (:product_family) { ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account) }
    let (:resource_handler) { ResourceHandler.create(resource_type_code: 'code', name: 'resource name', tool_proxy: tool_proxy) }

    describe "#launch_definitions" do

      it 'returns lti2 launch definitions' do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        rh = create_resource_handler(tp)
        mh = create_message_handler(rh)

        placements = ResourcePlacement::DEFAULT_PLACEMENTS
        placements.each { |p| rh.placements.create!(placement: p) }

        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq( {
          :definition_type => mh.class.name,
          :definition_id => mh.id,
          :name => rh.name,
          :description => rh.description,
          :domain => "samplelaunch",
          :placements => {
            :link_selection => {
              :message_type => "basic-lti-launch-request",
              :url => "https://samplelaunch/blti",
              :title => rh.name
            },
            :assignment_selection => {
              :message_type => "basic-lti-launch-request",
              :url => "https://samplelaunch/blti",
              :title => rh.name
            }
          }
        })

      end

      it 'returns an external tool definition' do
        tool = new_valid_external_tool(account)
        placements = %w(assignment_selection link_selection resource_selection)
        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq( {
          :definition_type => tool.class.name,
          :definition_id => tool.id,
          :name => tool.name,
          :description => tool.description,
          :domain => nil,
          :placements => {
            :link_selection => {
              :message_type => "basic-lti-launch-request",
              :url => "http://www.example.com/basic_lti",
              :title => tool.name
            },
            :assignment_selection => {
              :message_type => "basic-lti-launch-request",
              :url => "http://www.example.com/basic_lti",
              :title => tool.name
            }
          }
        })
      end

      it 'returns resource_selection tools' do
        tool = new_valid_external_tool(account, true)
        placements = %w(assignment_selection link_selection resource_selection)
        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 1
        definition = definitions.first
        expect(definition).to eq( {
          :definition_type => tool.class.name,
          :definition_id => tool.id,
          :name => tool.name,
          :description => tool.description,
          :domain => nil,
          :placements => {
            :assignment_selection => {
              :message_type => "basic-lti-launch-request",
              :url => "http://www.example.com/basic_lti",
              :title => tool.name
            },
            :link_selection => {
              :message_type => "basic-lti-launch-request",
              :url => "http://www.example.com/basic_lti",
              :title => tool.name
            },
            :resource_selection => {
              :message_type => "resource_selection",
              :url => "http://example.com/selection_test",
              :title => tool.name,
              :selection_width=>500,
              :selection_height=>500
            }
          }
        })
      end

      it 'returns an external tool and a message handler' do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        rh = create_resource_handler(tp)
        ResourcePlacement::DEFAULT_PLACEMENTS.each { |p| rh.placements.create(placement: p) }
        create_message_handler(rh)
        new_valid_external_tool(account)

        placements = %w(assignment_selection link_selection resource_selection)
        tools_collection = described_class.bookmarked_collection(account, placements).paginate(per_page: 100).to_a

        definitions = described_class.launch_definitions(tools_collection, placements)
        expect(definitions.count).to eq 2
        external_tool = definitions.find { |d| d[:definition_type] == 'ContextExternalTool' }
        message_handler = definitions.find { |d| d[:definition_type] == 'Lti::MessageHandler' }
        expect(message_handler).to_not be nil
        expect(external_tool).to_not be nil
      end

      context 'pagination' do
        it 'paginates correctly' do
          3.times do |_|
            tp = create_tool_proxy
            tp.bindings.create(context: account)
            rh = create_resource_handler(tp)
            ResourcePlacement::DEFAULT_PLACEMENTS.each { |p| rh.placements.create(placement: p) }
            create_message_handler(rh)
          end
          3.times { |_| new_valid_external_tool(account) }

          placements = %w(assignment_selection link_selection resource_selection)
          collection = described_class.bookmarked_collection(account, placements)
          per_page = 3
          page1 = collection.paginate(per_page: per_page)
          page2 = collection.paginate(page: page1.next_page, per_page: per_page)
          expect(page1.count).to eq 3
          expect(page2.count).to eq 3
          expect(page1.first).to_not eq page2.first
        end
      end

    end

    def create_tool_proxy(opts = {})
      default_opts = {
        context: account,
        shared_secret: 'shared_secret',
        guid: SecureRandom.uuid,
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        workflow_state: 'active',
        raw_data: 'some raw data'
      }
      ToolProxy.create(default_opts.merge(opts))
    end

    def create_resource_handler(tool_proxy, opts = {})
      default_opts = {resource_type_code: 'code', name: (0...8).map { (65 + rand(26)).chr }.join, description: 'foo', tool_proxy: tool_proxy}
      ResourceHandler.create(default_opts.merge(opts))
    end

    def create_message_handler(resource_handler, opts = {})
      default_ops = {message_type: 'basic-lti-launch-request', launch_path: 'https://samplelaunch/blti', resource_handler: resource_handler}
      MessageHandler.create(default_ops.merge(opts))
    end

    def new_valid_external_tool(context, resource_selection = false)
      tool = context.context_external_tools.new(name: (0...8).map { (65 + rand(26)).chr }.join,
                                                description: "foo",
                                                consumer_key: "key",
                                                shared_secret: "secret")
      tool.url = "http://www.example.com/basic_lti"
      tool.resource_selection = {:url => "http://example.com/selection_test", :selection_width => 500, :selection_height => 500} if resource_selection
      tool.save!
      tool
    end

  end
end