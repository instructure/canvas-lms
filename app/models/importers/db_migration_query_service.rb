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

module Importers
  # This class encapsulates the logic to retrieve metadata (for various types of assets)
  # given a migration id. This particular implementation relies on db queries in Canvas
  # but future implementations may rely on a static asset_migration_map
  #
  # Each function returns exactly one id (if available), and nil if an id
  # cannot be resolved
  class DbMigrationQueryService
    def initialize(context)
      @context = context
    end

    # Returns the path for the context, for a course, it should return something like
    # "courses/1"
    def context_path
      "/#{@context.class.to_s.underscore.pluralize}/#{@context.id}"
    end

    # Looks up a wiki page slug for a migration id
    def convert_wiki_page_migration_id_to_slug(migration_id)
      @context.wiki_pages.where(migration_id:).limit(1).pick(:url)
    end

    # looks up a discussion topic
    def convert_discussion_topic_migration_id(migration_id)
      @context.discussion_topics.where(migration_id:).limit(1).pick(:id)
    end

    def convert_context_module_tag_migration_id(migration_id)
      @context.context_module_tags.where(migration_id:).limit(1).pick(:id)
    end

    def convert_attachment_migration_id(migration_id)
      @context.attachments.where(migration_id:).limit(1).pick(:id)
    end
  end
end
