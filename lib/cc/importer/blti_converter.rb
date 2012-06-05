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
module CC::Importer
  module BLTIConverter
    include CC::Importer
    
    def get_blti_resources
      blti_resources = []

      @manifest.css("resource[type=#{BASIC_LTI}]").each do |r_node|
        res = {}
        res[:migration_id] = r_node['identifier']
        res[:href] = r_node['href']
        res[:files] = []
        r_node.css('file').each do |file_node|
          res[:files] << {:href => file_node[:href]}
        end

        blti_resources << res
      end

      blti_resources
    end

    def convert_blti_links(blti_resources=nil)
      blti_resources ||= get_blti_resources
      tools = []

      blti_resources.each do |res|
        path = res[:href] || res[:files].first[:href]
        path = get_full_path(path)

        if File.exists?(path)
          doc = open_file_xml(path)
          tool = convert_blti_link(doc)
          tool[:migration_id] = res[:migration_id]
          res[:url] = tool[:url] # for the organization item to reference
          
          tools << tool
        end
      end

      tools
    end
    
    def convert_blti_link(doc)
      blti = get_blti_namespace(doc)
      tool = {}
      tool[:description] = get_node_val(doc, "#{blti}|description")
      tool[:title] = get_node_val(doc, "#{blti}|title")
      tool[:url] = get_node_val(doc, "#{blti}|secure_launch_url")
      tool[:url] ||= get_node_val(doc, "#{blti}|launch_url")
      if custom_node = doc.css("#{blti}|custom")
        tool[:custom_fields] = get_custom_properties(custom_node)
      end
      doc.css("#{blti}|extensions").each do |extension|
        tool[:extensions] ||= []
        ext = {}
        ext[:platform] = extension['platform']
        ext[:custom_fields] = get_custom_properties(extension)
        
        if ext[:platform] == CANVAS_PLATFORM
          tool[:privacy_level] = ext[:custom_fields].delete 'privacy_level'
          tool[:domain] = ext[:custom_fields].delete 'domain'
          tool[:consumer_key] = ext[:custom_fields].delete 'consumer_key'
          tool[:shared_secret] = ext[:custom_fields].delete 'shared_secret'
          tool[:tool_id] = ext[:custom_fields].delete 'tool_id'
          if tool[:assignment_points_possible] = ext[:custom_fields].delete('outcome')
            tool[:assignment_points_possible] = tool[:assignment_points_possible].to_f
          end
          tool[:settings] = ext[:custom_fields]
        else
          tool[:extensions] << ext
        end
      end
      if icon = get_node_val(doc, "#{blti}|icon")
        tool[:settings] ||= {}
        tool[:settings][:icon_url] = icon
      end
      tool
    end
    
    def convert_blti_xml(xml)
      doc = Nokogiri::XML(xml)
      begin
        convert_blti_link(doc)
      rescue Nokogiri::XML::XPath::SyntaxError
        raise CCImportError.new(I18n.t(:invalid_xml_syntax, "invalid xml syntax"))
      end
    end
    
    def retrieve_and_convert_blti_url(url)
      begin
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        config_xml = response.body

        convert_blti_xml(config_xml)
      rescue Timeout::Error
        raise CCImportError.new(I18n.t(:retrieve_timeout, "could not retrieve configuration, the server response timed out"))
      end
    end
    
    def get_custom_properties(node)
      props = {}
      node.children.each do |property|
        next if property.name == 'text'
        if property.name == 'property'
          props[property['name']] = property.text
        elsif property.name == 'options'
          props[property['name']] = get_custom_properties(property)
        end
      end
      props
    end
    
    def get_blti_namespace(doc)
      doc.namespaces.each_pair do |key, val|
        if val == BLTI_NAMESPACE
          return key.gsub('xmlns:','')
        end
      end
      "blti"
    end

    def create_assignments_from_lti_links(lti_tools)
      asmnts = []

      lti_tools.each do |tool|
        if tool[:assignment_points_possible]
          asmnt = {:migration_id => tool[:migration_id]}
          asmnt[:title] = tool[:title]
          asmnt[:description] = tool[:description]
          asmnt[:submission_format] = "external_tool"
          asmnt[:external_tool_url] = tool[:url]
          asmnt[:grading_type] = 'points'
          asmnt[:points_possible] = tool[:assignment_points_possible]
          asmnts << asmnt
        end
      end

      asmnts
    end
    class CCImportError < Exception; end
  end
end
