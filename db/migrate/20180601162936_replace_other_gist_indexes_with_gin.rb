#
# Copyright (C) 2012 - present Instructure, Inc.
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

class ReplaceOtherGistIndexesWithGin < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    if (schema = connection.extension_installed?(:pg_trgm))
      add_index :users, "LOWER(short_name) #{schema}.gin_trgm_ops", name: "index_gin_trgm_users_short_name", using: :gin, algorithm: :concurrently
      add_index :users, "LOWER(name) #{schema}.gin_trgm_ops", name: "index_gin_trgm_users_name_active_only",
        using: :gin, algorithm: :concurrently, where: "workflow_state IN ('registered', 'pre_registered')"
      add_index :courses, "(
          coalesce(lower(name), '') || ' ' ||
          coalesce(lower(sis_source_id), '') || ' ' ||
          coalesce(lower(course_code), '')
        ) #{schema}.gin_trgm_ops",
        name: "index_gin_trgm_courses_composite_search",
        using: :gin,
        algorithm: :concurrently
      add_index :discussion_topics, "LOWER(title) #{schema}.gin_trgm_ops", name: "index_gin_trgm_discussion_topics_title", using: :gin, algorithm: :concurrently

      remove_index :users, name: "index_trgm_users_short_name"
      remove_index :users, name: "index_trgm_users_name_active_only"
      remove_index :courses, name: "index_trgm_courses_composite_search"
      remove_index :discussion_topics, name: "index_trgm_discussion_topics_title"
    end
  end

  def down
    if (schema = connection.extension_installed?(:pg_trgm))
      add_index :users, "LOWER(short_name) #{schema}.gist_trgm_ops", name: "index_trgm_users_short_name", using: :gist, algorithm: :concurrently
      add_index :users, "LOWER(name) #{schema}.gist_trgm_ops", name: "index_trgm_users_name_active_only",
        using: :gist, algorithm: :concurrently, where: "workflow_state IN ('registered', 'pre_registered')"
      add_index :courses, "(
          coalesce(lower(name), '') || ' ' ||
          coalesce(lower(sis_source_id), '') || ' ' ||
          coalesce(lower(course_code), '')
        ) #{schema}.gist_trgm_ops",
        name: "index_trgm_courses_composite_search",
        using: :gist,
        algorithm: :concurrently
      add_index :discussion_topics, "LOWER(title) #{schema}.gist_trgm_ops", name: "index_trgm_discussion_topics_title", using: :gist, algorithm: :concurrently

      remove_index :users, name: "index_gin_trgm_users_short_name"
      remove_index :users, name: "index_gin_trgm_users_name_active_only"
      remove_index :courses, name: "index_gin_trgm_courses_composite_search"
      remove_index :discussion_topics, name: "index_gin_trgm_discussion_topics_title"
    end
  end
end
