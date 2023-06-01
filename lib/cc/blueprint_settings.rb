# frozen_string_literal: true

# Copyright (C) 2022 - present Instructure, Inc.
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
  # NOTE: This information is used when copying a blueprint course itself, so the copy can retain
  # the blueprint setting and restriction information. It is *not* used in blueprint syncs!
  module BlueprintSettings
    def create_blueprint_settings(document = nil)
      return unless export_symbol?(:all_blueprint_settings)

      template = MasterCourses::MasterTemplate.full_template_for(@course)
      return unless template

      if document
        meta_file = nil
        rel_path = nil
      else
        meta_file = File.new(File.join(@canvas_resource_dir, CCHelper::BLUEPRINT_SETTINGS), "w")
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::BLUEPRINT_SETTINGS)
        document = Builder::XmlMarkup.new(target: meta_file, indent: 2)
      end

      document.instruct!
      document.blueprint_settings("xmlns" => CCHelper::CANVAS_NAMESPACE,
                                  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                                  "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}") do |bs|
        bs.use_default_restrictions_by_type template.use_default_restrictions_by_type
        bs.restrictions do |r|
          r.restriction({ content_type: "default" }.merge(template.default_restrictions))
          template.default_restrictions_by_type.each do |content_type, restriction|
            r.restriction({ content_type: }.merge(restriction))
          end
        end
        bs.restricted_items do |items|
          template.master_content_tags.where.not(restrictions: {}).find_each do |tag|
            if export_object?(tag.content)
              items.item(identifierref: create_key(tag.content)) do |item|
                item.restriction({ content_type: tag.content_type }.merge(tag.restrictions))
                item.use_default_restrictions tag.use_default_restrictions
              end
            end
          end
        end
      end

      meta_file&.close
      rel_path
    end
  end
end
