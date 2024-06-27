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

module CC
  # Exports all Lti::ResourceLinks other than those related
  # to an assignment.
  #
  # Assignment Lti::ResourceLinks are exported in
  # CC::AssignmentResources.
  module LtiResourceLinks
    # Export all resource links with a context set to
    # the coures being exported or associated with
    # an assignment in that course.
    #
    # One `resource` element in the manifest and one
    # document in the `lti_resource_links` directory
    # of the package per resource link.
    def add_lti_resource_links
      Lti::ResourceLink.where(context: @course.assignments.active)
                       .union(@course.lti_resource_links)
                       .active
                       .find_each do |resource_link|
        tool = resource_link.current_external_tool(@course)
        next if tool.blank?

        migration_id = create_key(resource_link)

        rl_document = create_resource_link_document(migration_id)

        add_lti_resource_link(resource_link, tool, rl_document.document)

        rl_document.file.close

        # Add a resource element to the root of the manifest
        @resources.resource(identifier: migration_id, type: CCHelper::BASIC_LTI_1_DOT_3) do |res|
          res.file(href: "#{CCHelper::RESOURCE_LINK_FOLDER}/#{rl_document.file_name}")
        end
      end
    end

    # Creates a file and XML document pointing to that
    # file to write a new resource link export.
    #
    # Additionally creates the root resource link
    # ID folder in the migration structure if it does
    # not exist
    def create_resource_link_document(migration_id)
      folder = File.join(@export_dir, CCHelper::RESOURCE_LINK_FOLDER)
      FileUtils.mkdir_p(folder)

      document_info = { file_name: "#{migration_id}.xml" }
      path = File.join(folder, document_info[:file_name])
      document_info[:file] = File.new(path, "w")
      document_info[:document] = Builder::XmlMarkup.new(target: document_info[:file], indent: 2)

      OpenStruct.new(document_info)
    end

    # Populates a document with the `imslticc_v1p3` representation
    # of an LTi::ResourceLink
    #
    # Canvas exports/imports these documents to preserve
    # custom parameters set by a tool at a per-link level
    # via custom parameters
    def add_lti_resource_link(resource_link, tool, document)
      document.instruct!
      document.cartridge_basiclti_link(
        :xmlns => "http://www.imsglobal.org/xsd/imslticc_v1p3",
        "xmlns:blti" => "http://www.imsglobal.org/xsd/imsbasiclti_v1p0",
        "xmlns:lticm" => "http://www.imsglobal.org/xsd/imslticm_v1p0",
        "xmlns:lticp" => "http://www.imsglobal.org/xsd/imslticp_v1p0",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => %w[
          http://www.imsglobal.org/xsd/imslticc_v1p3.xsd
          http://www.imsglobal.org/xsd/imslticp_v1p0
          imslticp_v1p0.xsd
          http://www.imsglobal.org/xsd/imslticm_v1p0
          imslticm_v1p0.xsd
          http://www.imsglobal.org/xsd/imsbasiclti_v1p0
          imsbasiclti_v1p0p1.xsd
        ].join(" ")
      ) do |cartridge_basiclti_link|
        # Basic elements
        cartridge_basiclti_link.blti :title, tool.name
        cartridge_basiclti_link.blti :description, tool.description

        # URL element (choose secure or not based on protocol)
        case tool.url
        when %r{^http://}
          cartridge_basiclti_link.blti :launch_url, tool.url
        when %r{^https://}
          cartridge_basiclti_link.blti :secure_launch_url, tool.url
        end

        # Custom parameters from the resource link
        cartridge_basiclti_link.blti(:custom) do |custom|
          resource_link.custom&.each do |k, v|
            custom.lticm :property, v, name: k
          end
        end

        # Extensions
        cartridge_basiclti_link.blti(:extensions, platform: CC::CCHelper::CANVAS_PLATFORM) do |extensions|
          extensions.lticm(
            :property,
            resource_link.lookup_uuid,
            name: "lookup_uuid"
          )
          unless resource_link.url.nil?
            extensions.lticm(
              :property,
              # 'url' refers to the actual target_link_uri, whereas 'launch_url'
              #   is only used to look up the tool
              resource_link.url,
              name: "resource_link_url"
            )
          end
        end
      end
    end
  end
end
