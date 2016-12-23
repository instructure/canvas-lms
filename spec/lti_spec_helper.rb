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
module LtiSpecHelper
  def create_tool_proxy(opts = {})

    default_opts = {
      shared_secret: 'shared_secret',
      guid: SecureRandom.uuid,
      product_version: '1.0beta',
      lti_version: 'LTI-2p0',
      product_family: find_or_create_product_family,
      workflow_state: 'active',
      raw_data: 'some raw data',
      name: (0...8).map { (65 + rand(26)).chr }.join,
    }
    combined_opts = default_opts.merge(opts)
    combined_opts[:context] = Account.create!(name: 'Test Account') unless combined_opts.has_key?(:context)
    combined_opts[:product_family] = find_or_create_product_family(combined_opts[:context]) unless combined_opts.has_key?(:product_family)
    Lti::ToolProxy.create!(combined_opts)
  end

  def find_or_create_product_family(opts = {})
    default_opts = {vendor_code: '123', product_code: 'abc', vendor_name: 'acme'}
    default_opts[:root_account_id] = Account.create!(name: 'Test Account') unless opts.has_key?(:root_account_id)
    Lti::ProductFamily.where(default_opts.merge(opts)).first_or_create
  end

  def create_resource_handler(tool_proxy, opts = {})
    default_opts = {resource_type_code: 'code', name: (0...8).map { (65 + rand(26)).chr }.join, tool_proxy: tool_proxy}
    Lti::ResourceHandler.create(default_opts.merge(opts))
  end

  def create_message_handler(resource_handler, opts = {})
    default_ops = {
      message_type: 'basic-lti-launch-request',
      launch_path: 'https://samplelaunch/blti',
      resource_handler: resource_handler
    }
    Lti::MessageHandler.create(default_ops.merge(opts))
  end

  def new_valid_external_tool(context, resource_selection = false)
    tool = context.context_external_tools.new(:name => (0...8).map { (65 + rand(26)).chr }.join,
                                              :consumer_key => "key",
                                              :shared_secret => "secret")
    tool.url = "http://www.example.com/basic_lti"
    tool.resource_selection = {
      :url => "http://example.com/selection_test",
      :selection_width => 400,
      :selection_height => 400
    } if resource_selection
    tool.save!
    tool
  end
end
