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
module CC::Importer::Canvas
  module WikiConverter
    include CC::Importer

    def convert_wikis
      wikis = []

      wiki_dir = @package_root.item_path(WIKI_FOLDER)
      Dir["#{wiki_dir}/**/**"].each do |path|
        next if File.directory?(path)

        doc = json?(path) ? open_json(path) : open_file_html5(path)
        wikis << convert_wiki(doc, path)
      end

      wikis
    end

    def open_json(path)
      JSON.parse File.read(path)
    end

    def json?(path)
      File.basename(path)[-5..] == ".json"
    end

    def convert_wiki(doc, path)
      wiki = {}

      wiki_name = File.basename(path).sub(".html", "").sub(".json", "")

      if json?(path)
        title, block_editor, meta = doc.slice("title", "block_editor", "meta").values
      else
        title, body, meta = begin
          get_html_title_and_body_and_meta_fields(doc)
        rescue EncodingError
          get_html_title_and_body_and_meta_fields(open_file_xml(path))
        end
      end

      wiki[:title] = title
      wiki[:migration_id] = meta["identifier"]
      wiki[:editing_roles] = meta["editing_roles"]
      wiki[:notify_of_update] = meta["notify_of_update"] == "true"
      wiki[:workflow_state] = meta["workflow_state"]
      # should keep in case we import old packages
      wiki[:workflow_state] = "unpublished" if meta["hide_from_students"] == "true" && (wiki[:workflow_state].nil? || wiki[:workflow_state] == "active")
      wiki[:front_page] = meta["front_page"] == "true"
      wiki[:text] = body if body
      wiki[:url_name] = wiki_name
      wiki[:assignment] = nil
      wiki[:todo_date] = meta["todo_date"]
      wiki[:publish_at] = meta["publish_at"]
      wiki[:unlock_at] = meta["unlock_at"]
      wiki[:lock_at] = meta["lock_at"]
      wiki[:block_editor] = block_editor if block_editor
      if (asg_id = meta["assignment_identifier"])
        wiki[:assignment] = {
          migration_id: asg_id,
          submission_types: "wiki_page",
          only_visible_to_overrides: meta["only_visible_to_overrides"] == "true",
          assignment_overrides: wiki_assignment_overrides(meta)
        }
      end
      wiki
    end

    def wiki_assignment_overrides(meta)
      return [] unless meta["assignment_overrides"]

      JSON.parse(meta["assignment_overrides"])
    end
  end
end
