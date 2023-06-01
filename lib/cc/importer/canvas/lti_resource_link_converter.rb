# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
module CC::Importer::Canvas
  module LtiResourceLinkConverter
    include CC::Importer

    FLOAT_REGEX = /^[-+]?\d+[.]\d+$/
    INTEGER_REGEX = /^[-+]?\d+$/

    def convert_lti_resource_links
      resource_links = []

      @manifest.css("resource[type$=imsbasiclti_xmlv1p3]").each do |resource|
        identifier = resource.attributes["identifier"].value
        resource_link_element = resource.at_css("file[href$='lti_resource_links/#{identifier}.xml']")

        next unless resource_link_element

        path = @package_root.item_path(resource_link_element["href"])
        document = open_file_xml(path)

        next unless document

        custom = {}
        lookup_uuid = nil
        resource_link_url = nil

        document.xpath("//blti:custom//lticm:property").each do |el|
          key = el.attributes["name"].value
          value = el.content

          next if key.empty?

          # As `el.content` returns a String, we're trying to convert the
          # custom parameter value to the orignal data type
          value = if FLOAT_REGEX.match? value
                    value.to_f
                  elsif INTEGER_REGEX.match? value
                    value.to_i
                  elsif value == "true"
                    true
                  elsif value == "false"
                    false
                  else
                    value
                  end

          custom[key.to_sym] = value
        end

        document.xpath("//blti:extensions//lticm:property").each do |el|
          lookup_uuid = el.content if el.attributes["name"].value == "lookup_uuid"
          resource_link_url = el.content if el.attributes["name"].value == "resource_link_url"
        end

        launch_url = (document.xpath("//blti:launch_url").first || document.xpath("//blti:secure_launch_url").first)&.content

        next unless launch_url

        resource_links << {
          custom:,
          launch_url:,
          lookup_uuid:,
          resource_link_url:
        }
      end

      resource_links
    end
  end
end
