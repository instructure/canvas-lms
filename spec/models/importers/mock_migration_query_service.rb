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

module LinkConverters
  # This class privides a mock of the logic to retrieve a new id (for various types of assets)
  # given a migration id.
  class MockMigrationQueryService
    def initialize(context_path: "/", assets: {})
      @context_path = context_path
      @assets = assets
    end

    attr_reader :context_path

    # Looks up a wiki page slug for a migration id
    def convert_wiki_page_migration_id_to_slug(migration_id)
      @assets[:wiki_pages][migration_id]
    end

    # looks up a discussion topic
    def convert_discussion_topic_migration_id(migration_id)
      @assets[:discussion_topics][migration_id]
    end

    def convert_context_module_tag_migration_id(migration_id)
      @assets[:context_module_tags][migration_id]
    end

    def convert_attachment_migration_id(migration_id)
      @assets[:attachments][migration_id]
    end
  end
end
