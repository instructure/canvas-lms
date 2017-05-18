#
# Copyright (C) 2013 - present Instructure, Inc.
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

class RemoveUnneededGistIndexes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if is_postgres?
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_wiki_pages_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_context_external_tools_name')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_assignments_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_quizzes_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_discussion_topics_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_attachments_display_name')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_context_modules_name')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_content_tags_title')}")
    end
  end

  def self.down
  end
end
