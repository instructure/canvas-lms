# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CC::Exporter::Epub::Converters
  module WikiEpubConverter
    include CC::Exporter
    include CC::CCHelper

    def convert_wikis
      wikis = []

      wiki_dir = @package_root.item_path("wiki_content")
      Dir["#{wiki_dir}/**/**"].each do |path|
        doc = open_file_xml(path)
        workflow_state = get_node_val(doc, "meta[name=workflow_state] @content")
        module_locked = get_bool_val(doc, "meta[name=module_locked] @content")
        next unless workflow_state == "active" && !module_locked

        wikis << convert_wiki(doc, path)
      end

      wikis
    end

    def convert_wiki(doc, path)
      wiki = {}
      wiki_name = File.basename(path, ".html")
      title, body, meta = get_html_title_and_body_and_meta_fields(doc)
      wiki[:title] = title
      wiki[:front_page] = meta["front_page"] == "true"
      wiki[:text] = body
      wiki[:identifier] = meta["identifier"] || wiki_name
      wiki[:href] = "pages.xhtml##{wiki[:identifier]}"
      wiki
    end
  end
end
