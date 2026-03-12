# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
  module NavMenuLinks
    def create_nav_menu_links(document = nil)
      scope = NavMenuLink.active.where(course_nav: true, course: @course)
      return nil if scope.empty?

      if document
        nav_menu_links_file = nil
        rel_path = nil
      else
        nav_menu_links_file = File.new(File.join(@canvas_resource_dir, CCHelper::NAV_MENU_LINKS), "w")
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::NAV_MENU_LINKS)
        document = Builder::XmlMarkup.new(target: nav_menu_links_file, indent: 2)
      end

      document.instruct!
      document.navMenuLinks(
        "xmlns" => CCHelper::CANVAS_NAMESPACE,
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |links_node|
        scope.find_each do |nav_menu_link|
          links_node.navMenuLink(identifier: create_key(nav_menu_link)) do |link_node|
            link_node.label nav_menu_link.label
            # Translate internal links to migration ID placeholders
            link_node.url @html_exporter.translate_url(nav_menu_link.url)
          end
        end
      end

      nav_menu_links_file&.close
      rel_path
    end
  end
end
