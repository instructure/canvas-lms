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

class AddMoreGistIndexes < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if is_postgres? && (schema = connection.extension_installed?(:pg_trgm))
      add_index :users, "LOWER(short_name) #{schema}.gist_trgm_ops", name: "index_trgm_users_short_name", using: :gist, algorithm: :concurrently
      add_index :courses, "LOWER(name) #{schema}.gist_trgm_ops", name: "index_trgm_courses_name", using: :gist, algorithm: :concurrently
      add_index :courses, "LOWER(course_code) #{schema}.gist_trgm_ops", name: "index_trgm_courses_course_code", using: :gist, algorithm: :concurrently
      add_index :courses, "LOWER(sis_source_id) #{schema}.gist_trgm_ops", name: "index_trgm_courses_sis_source_id", using: :gist, algorithm: :concurrently
    end
  end

  def self.down
    remove_index :users, name: 'index_trgm_users_short_name'
    remove_index :courses, name: 'index_trgm_courses_name'
    remove_index :courses, name: 'index_trgm_courses_course_code'
    remove_index :courses, name: 'index_trgm_courses_sis_source_id'
  end
end
