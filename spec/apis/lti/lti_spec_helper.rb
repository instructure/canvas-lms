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

def create_tool_proxy(opts = {})
  default_opts = {
    context: account,
    shared_secret: 'shared_secret',
    guid: SecureRandom.uuid,
    product_version: '1.0beta',
    lti_version: 'LTI-2p0',
    product_family: create_product_family,
    workflow_state: 'active',
    raw_data: 'some raw data'
  }
  Lti::ToolProxy.create(default_opts.merge(opts))
end

def create_product_family(opts = {})
  default_opts = {vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account}
  Lti::ProductFamily.create(default_opts.merge(opts))
end

def create_resource_handler(tool_proxy, opts = {})
  default_opts = {resource_type_code: 'code', name: (0...8).map { (65 + rand(26)).chr }.join, tool_proxy: tool_proxy}
  Lti::ResourceHandler.create(default_opts.merge(opts))
end

def create_message_handler(resource_handler, opts = {})
  default_ops = {message_type: 'basic-lti-launch-request', launch_path: 'https://samplelaunch/blti', resource_handler: resource_handler}
  Lti::MessageHandler.create(default_ops.merge(opts))
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