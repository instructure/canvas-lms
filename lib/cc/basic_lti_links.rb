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
      return nil unless @manifest.basic_ltis.length > 0

      @manifest.basic_ltis.each do |ct| # These are content tags

        migration_id = CCHelper::create_key(ct)

        lti_file_name = "#{migration_id}.xml"
        lti_path = File.join(@export_dir, lti_file_name)
        lti_file = File.new(lti_path, 'w')
        lti_doc = Builder::XmlMarkup.new(:target=>lti_file, :indent=>2)
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
          blti_node.tag! "blti:title", ct.title
          if ct.url =~ %r{http://}
            blti_node.tag! "blti:launch_url", ct.url
          elsif ct.url =~ %r{https://}  
            blti_node.tag! "blti:secure_launch_url", ct.url
          end
          blti_node.tag! "blti:vendor" do |v_node|
            v_node.tag! "lticp:code", 'unknown'
            v_node.tag! "lticp:name", 'unknown'
          end
        end
        lti_file.close

        @resources.resource(
                :identifier => migration_id,
                "type" => CCHelper::BASIC_LTI
        ) do |res|
          res.file(:href=>lti_file_name)
        end
      end

    end

    def create_external_tools(document=nil)
      return nil unless @course.context_external_tools.count > 0
      
      if document
        lti_file = nil
        rel_path = nil
      else
        lti_file = File.new(File.join(@canvas_resource_dir, CCHelper::EXTERNAL_TOOLS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::EXTERNAL_TOOLS)
        document = Builder::XmlMarkup.new(:target=>lti_file, :indent=>2)
      end
      
      document.instruct!
      document.externalTools(
          "xmlns" => CCHelper::CANVAS_NAMESPACE,
          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |et_node|
        @course.context_external_tools.each do |tool|
          migration_id = CCHelper.create_key(tool)
          et_node.externalTool(:identifier=>migration_id) do |t_node|
            t_node.title tool.name
            t_node.description tool.description unless tool.description.blank?
            t_node.url tool.url unless tool.url.blank?
            t_node.domain tool.domain unless tool.domain.blank?
            t_node.privacy_level tool.workflow_state
            t_node.comment! "The Consumer Key and Shared Secret will need to be configured within Canvas"
          end
        end
      end

      lti_file.close if lti_file
      rel_path
    end
  end
end