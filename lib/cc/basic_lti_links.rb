#
# Copyright (C) 2011 Instructure, Inc.
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
module CC
  module BasicLTILinks
    def create_basic_lti_links
      return nil unless @course.context_external_tools.active.count > 0

      @course.context_external_tools.active.each do |tool|
        next unless export_object?(tool)
        migration_id = CCHelper::create_key(tool)

        lti_file_name = "#{migration_id}.xml"
        lti_path = File.join(@export_dir, lti_file_name)
        lti_file = File.new(lti_path, 'w')
        lti_doc = Builder::XmlMarkup.new(:target=>lti_file, :indent=>2)

        create_blti_link(tool, lti_doc)
        
        lti_file.close

        @resources.resource(
                :identifier => migration_id,
                "type" => CCHelper::BASIC_LTI
        ) do |res|
          res.file(:href=>lti_file_name)
        end
      end
    end

    def create_blti_link(tool, lti_doc)
      lti_doc.instruct!
      lti_doc.cartridge_basiclti_link("xmlns" => "http://www.imsglobal.org/xsd/imslticc_v1p0",
                                      "xmlns:blti" => 'http://www.imsglobal.org/xsd/imsbasiclti_v1p0',
                                      "xmlns:lticm" => 'http://www.imsglobal.org/xsd/imslticm_v1p0',
                                      "xmlns:lticp" => 'http://www.imsglobal.org/xsd/imslticp_v1p0',
                                      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                                      "xsi:schemaLocation"=> "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
                          http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd
                          http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
                          http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd"
      ) do |blti_node|
        blti_node.blti :title, tool.name
        blti_node.blti :description, tool.description
        if tool.url =~ %r{http://}
          blti_node.blti :launch_url, tool.url
        elsif tool.url =~ %r{https://}
          blti_node.blti :secure_launch_url, tool.url
        end
        blti_node.blti(:icon, tool.settings[:icon_url]) if tool.settings[:icon_url]
        blti_node.blti :vendor do |v_node|
          v_node.lticp :code, 'unknown'
          v_node.lticp :name, 'unknown'
        end
        
        if tool.settings[:custom_fields]
          blti_node.tag!("blti:custom") do |custom_node|
            tool.settings[:custom_fields].each_pair do |key, val|
              custom_node.lticm :property, val, 'name' => key
            end
          end
        end

        blti_node.blti(:extensions, :platform => CC::CCHelper::CANVAS_PLATFORM) do |ext_node|
          ext_node.lticm(:property, tool.tool_id, 'name' => 'tool_id') if tool.tool_id
          ext_node.lticm :property, tool.workflow_state, 'name' => 'privacy_level'
          ext_node.lticm(:property, tool.domain, 'name' => 'domain') unless tool.domain.blank?
          if for_course_copy
            ext_node.lticm :property, tool.consumer_key, 'name' => 'consumer_key'
            ext_node.lticm :property, tool.shared_secret, 'name' => 'shared_secret'
          end
          ContextExternalTool::EXTENSION_TYPES.each do |type|
            if tool.settings[type]
              ext_node.lticm(:options, :name => type.to_s) do |type_node|
                type_node.lticm(:property, tool.settings[type][:url], 'name' => 'url') if tool.settings[type][:url]
                type_node.lticm(:property, tool.settings[type][:text], 'name' => 'text') if tool.settings[type][:text]
                if [:resource_selection,:editor_button,:homework_submission].include?(type)
                  type_node.lticm(:property, tool.settings[type][:selection_width], 'name' => 'selection_width')
                  type_node.lticm(:property, tool.settings[type][:selection_height], 'name' => 'selection_height')
                end
                if type == :course_navigation
                  type_node.lticm(:property, tool.settings[type][:visibility], 'name' => 'visibility') if tool.settings[type][:visibility]
                  type_node.lticm(:property, tool.settings[type][:default], 'name' => 'default') if tool.settings[type][:default]
                end
                if type == :editor_button
                  type_node.lticm(:property, tool.settings[type][:icon_url], 'name' => 'icon_url') if tool.settings[type][:icon_url]
                end
                if tool.settings[type][:labels]
                  type_node.lticm(:options, :name => 'labels') do |labels_node|
                    tool.settings[type][:labels].each do |lang, text|
                      labels_node.lticm(:property, text, 'name' => lang)
                    end
                  end
                end
                if tool.settings[type][:custom_fields]
                  type_node.tag!("blti:custom") do |custom_node|
                    tool.settings[type][:custom_fields].each_pair do |key, val|
                      custom_node.lticm :property, val, 'name' => key
                    end
                  end
                end
              end
            end
          end
        end
        
        if tool.settings[:vendor_extensions]
          tool.settings[:vendor_extensions].each do |extension|
            blti_node.blti(:extensions, :platform => extension[:platform]) do |ext_node|
              extension[:custom_fields].each_pair do |key, val|
                ext_node.lticm :property, val, 'name' => key
              end
            end
          end
        end
      end
    end
    
  end
end