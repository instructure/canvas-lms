# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "nokogiri"

module CC
  class NewQuizzesLinksReplacer
    def initialize(manifest)
      @course = manifest.exporter.course
      @user = manifest.exporter.user
      @manifest = manifest
    end

    def replace_links(xml)
      doc = Nokogiri::XML(xml || "")
      doc.search("*").each do |node|
        next unless node.node_name == "mattext" && node["texttype"] == "text/html"

        node.content = html_exporter.html_content(node.content)
      end

      doc.to_xml
    end

    def html_exporter
      @html_exporter ||= CCHelper::HtmlContentExporter.new(@course,
                                                           @user,
                                                           for_course_copy: false,
                                                           key_generator: @manifest)
    end
  end
end
