# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
module CanvasLinkMigrator
  # This class encapsulates the logic to retrieve metadata (for various types of assets)
  # given a migration id. This particular implementation relies on the migration object Canvas
  # creates
  #
  # Each function returns exactly one id (if available), and nil if an id
  # cannot be resolved
  #
  class ResourceMapService
    attr_reader :migration_data

    def initialize(migration_data)
      @migration_data = migration_data
    end

    def resources
      migration_data["resource_mapping"]
    end

    # Returns the path for the context, for a course, it should return something like
    # "courses/1"
    def context_path
      "/courses/#{migration_data["source_course"]}"
    end

    # Looks up a wiki page slug for a migration id
    def convert_wiki_page_migration_id_to_slug(migration_id)
      resources.dig("wiki_pages", migration_id, "destination", "url")
    end

    # looks up a discussion topic
    def convert_discussion_topic_migration_id(migration_id)
      resources.dig("discussion_topics", migration_id, "destination", "id")
    end

    def convert_context_module_tag_migration_id(migration_id)
      resources.dig("module_items", migration_id, "destination", "id")
    end

    def convert_attachment_migration_id(migration_id)
      resources.dig("files", migration_id, "destination", "id")
    end
  end
end
