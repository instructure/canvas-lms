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
module LtiSpecHelper
  def create_tool_proxy(opts = {})
    default_opts = {
      shared_secret: "shared_secret",
      guid: SecureRandom.uuid,
      product_version: "1.0beta",
      lti_version: "LTI-2p0",
      product_family: find_or_create_product_family,
      workflow_state: "active",
      raw_data: "some raw data",
      name: (0...8).map { rand(65..90).chr }.join,
    }
    combined_opts = default_opts.merge(opts)
    combined_opts[:context] = Account.create!(name: "Test Account") unless combined_opts.key?(:context)
    combined_opts[:product_family] = find_or_create_product_family(combined_opts[:context]) unless combined_opts.key?(:product_family)
    Lti::ToolProxy.create!(combined_opts)
  end

  def find_or_create_product_family(opts = {})
    default_opts = { vendor_code: "123", product_code: "abc", vendor_name: "acme" }
    default_opts[:root_account_id] = Account.create!(name: "Test Account") unless opts.key?(:root_account_id)
    Lti::ProductFamily.where(default_opts.merge(opts)).first_or_create
  end

  def create_resource_handler(tool_proxy, opts = {})
    default_opts = { resource_type_code: "code", name: (0...8).map { rand(65..90).chr }.join, tool_proxy: }
    Lti::ResourceHandler.create(default_opts.merge(opts))
  end

  def create_message_handler(resource_handler, opts = {})
    default_ops = {
      message_type: "basic-lti-launch-request",
      launch_path: "https://samplelaunch/blti",
      resource_handler:
    }
    Lti::MessageHandler.create(default_ops.merge(opts))
  end

  def new_valid_external_tool(context, resource_selection = false)
    tool = context.context_external_tools.new(name: (0...8).map { rand(65..90).chr }.join,
                                              consumer_key: "key",
                                              shared_secret: "secret")
    tool.url = "http://www.example.com/basic_lti"
    if resource_selection
      tool.resource_selection = {
        url: "http://example.com/selection_test",
        selection_width: 400,
        selection_height: 400
      }
    end
    tool.save!
    tool
  end

  def valid_tool_config
    <<~XML
      <?xml version='1.0' encoding='UTF-8'?>
      <cartridge_basiclti_link xmlns='http://www.imsglobal.org/xsd/imslticc_v1p0' xmlns:blti='http://www.imsglobal.org/xsd/imsbasiclti_v1p0' xmlns:lticm='http://www.imsglobal.org/xsd/imslticm_v1p0' xmlns:lticp='http://www.imsglobal.org/xsd/imslticp_v1p0' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd'>
        <blti:title>YouTube</blti:title>
        <blti:description>Search publicly available YouTube videos. A new icon will show up in your course rich editor letting you search YouTube and click to embed videos in your course material.</blti:description>
        <blti:launch_url>https://www.edu-apps.org/lti_public_resources/?tool_id=youtube</blti:launch_url>
        <blti:custom>
            <lticm:property name='channel_name'>foo-bar</lticm:property>
        </blti:custom>
        <blti:extensions platform='canvas.instructure.com'>
            <lticm:property name='domain'>www.edu-apps.org</lticm:property>
            <lticm:options name='editor_button'>
              <lticm:property name='enabled'>true</lticm:property>
            </lticm:options>
            <lticm:property name='icon_url'>https://www.edu-apps.org/assets/lti_public_resources/youtube_icon.png</lticm:property>
            <lticm:property name='privacy_level'>anonymous</lticm:property>
            <lticm:options name='resource_selection'>
              <lticm:property name='enabled'>true</lticm:property>
            </lticm:options>
            <lticm:property name='selection_height'>600</lticm:property>
            <lticm:property name='selection_width'>560</lticm:property>
            <lticm:property name='text'>YouTube</lticm:property>
            <lticm:property name='tool_id'>youtube</lticm:property>
        </blti:extensions>
      </cartridge_basiclti_link>
    XML
  end
end
