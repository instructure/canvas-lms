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

require 'nokogiri'

module CC::Importer
  class BLTIConverter
    class CCImportError < Exception; end
    include CC::Importer
    
    def get_blti_resources(manifest)
      blti_resources = []

      manifest.css("resource[type=#{BASIC_LTI}]").each do |r_node|
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

    def convert_blti_links(blti_resources, converter)
      tools = []

      blti_resources.each do |res|
        path = res[:href] || (res[:files] && res[:files].first && res[:files].first[:href])
        path = converter.get_full_path(path)

        if File.exist?(path)
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
      blti = nil unless doc.namespaces["xmlns:#{blti}"]
      link_css_path = "cartridge_basiclti_link"
      tool = {}
      tool[:description] = get_node_val(doc, "#{link_css_path} > #{blti}|description")
      tool[:title] = get_node_val(doc, "#{link_css_path} > #{blti}|title")
      tool[:url] = get_node_val(doc, "#{link_css_path} > #{blti}|secure_launch_url")
      tool[:url] ||= get_node_val(doc, "#{link_css_path} > #{blti}|launch_url")
      if custom_node = doc.css("#{link_css_path} > #{blti}|custom").first
        tool[:custom_fields] = get_custom_properties(custom_node)
      end
      tool[:custom_fields] ||= {}

      doc.css("#{link_css_path} > #{blti}|extensions").each do |extension|
        tool[:extensions] ||= []
        ext = {}
        ext[:platform] = extension['platform']
        ext[:custom_fields] = get_custom_properties(extension)
        
        if ext[:platform] == CANVAS_PLATFORM
          tool[:privacy_level] = ext[:custom_fields].delete 'privacy_level'
          tool[:not_selectable] = ext[:custom_fields].delete 'not_selectable'
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
      if icon = get_node_val(doc, "#{link_css_path} > #{blti}|icon")
        tool[:settings] ||= {}
        tool[:settings][:icon_url] = icon
      end
      tool
    end
    
    def convert_blti_xml(xml)
      doc = create_xml_doc(xml)
      if !doc.namespaces.to_s.downcase.include? 'imsglobal'
        raise CCImportError.new(I18n.t("Invalid XML Configuration"))
      end
      begin
        tool = convert_blti_link(doc)
        check_for_unescaped_url_properties(tool) if tool
      rescue Nokogiri::XML::XPath::SyntaxError
        raise CCImportError.new(I18n.t(:invalid_xml_syntax, "Invalid xml syntax"))
      end
      tool
    end

    def check_for_unescaped_url_properties(obj)
      # Recursively look for properties named 'url'
      if obj.is_a?(Hash)
        obj.select{|k, v| k.to_s == 'url' && v.is_a?(String)}.each do |k, v|
          check_for_unescaped_url(v)
        end
        obj.each{|k, v| check_for_unescaped_url_properties(v)}
      elsif obj.is_a?(Array)
        obj.each{|o| check_for_unescaped_url_properties(o)}
      end
    end

    def check_for_unescaped_url(url)
      if (url =~ /(.*[^\=]*\?*\=)[^\&]*\=/)
        raise CCImportError.new(I18n.t(:invalid_url_in_xml, "Invalid url in xml. Ampersands must be escaped."))
      end
    end

    def fetch(url, limit = 10)
      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      case response
        when Net::HTTPRedirection then fetch(response['location'], limit - 1)
        else
          response
      end
    end

    def retrieve_and_convert_blti_url(url)
      begin
        response = fetch(url)
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
        elsif property.name == 'custom'
          props[:custom_fields] = get_custom_properties(property)
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
  end
end
