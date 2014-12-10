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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

module Lti
  describe LtiAppsController, type: :request do

    let (:account) { Account.create }
    let (:product_family) { ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account) }

    describe '#launch_definitions' do

      before do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        rh = create_resource_handler(tp)
        @mh = create_message_handler(rh)
        @external_tool = new_valid_external_tool(account)
      end

      it 'returns a list of launch definitions for a context and placements' do
        course_with_teacher(active_all: true, user: user_with_pseudonym, account: account)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                 {controller: 'lti/lti_apps', action: 'launch_definitions', format: 'json',
                  placements: %w(module_item resource_selection), course_id: @course.id.to_s})
        expect(json.select {|j| j['definition_type'] == @mh.class.name && j['definition_id'] == @mh.id.to_s}).not_to be_nil
        expect(json.select {|j| j['definition_type'] == @external_tool.class.name && j['definition_id'] == @external_tool.id.to_s}).not_to be_nil
      end

      it 'paginates the launch definitions' do
        5.times { |_| new_valid_external_tool(account) }
        course_with_teacher(active_all: true, user: user_with_pseudonym, account: account)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions?per_page=3",
                        {controller: 'lti/lti_apps', action: 'launch_definitions', format: 'json',
                         placements: Lti::ResourcePlacement::DEFAULT_PLACEMENTS, course_id: @course.id.to_s, per_page: '3'})

        json_next = follow_pagination_link('next', :controller => 'lti/lti_apps', :action => 'launch_definitions')
        expect(json.count).to eq 3
        expect(json_next.count).to eq 3
        json
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
      default_opts = {resource_type_code: 'code', name: (0...8).map { (65 + rand(26)).chr }.join, tool_proxy: tool_proxy}
      ResourceHandler.create(default_opts.merge(opts))
    end

    def create_message_handler(resource_handler, opts = {})
      default_ops = {message_type: 'basic-lti-launch-request', launch_path: 'https://samplelaunch/blti', resource_handler: resource_handler}
      MessageHandler.create(default_ops.merge(opts))
    end

    def new_valid_external_tool(context, resource_selection = false)
      tool = context.context_external_tools.new(:name => (0...8).map { (65 + rand(26)).chr }.join,
                                                :consumer_key => "key",
                                                :shared_secret => "secret")
      tool.url = "http://www.example.com/basic_lti"
      tool.resource_selection = {:url => "http://example.com/selection_test", :selection_width => 400, :selection_height => 400} if resource_selection
      tool.save!
      tool
    end

  end
end