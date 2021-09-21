# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class ChangeCourseGistIndexesToGin < ActiveRecord::Migration[6.0]
  tag :postdeploy
  disable_ddl_transaction!

  def redo_trgm_index(column, type, trgm)
    if index_name_exists?(:courses, "index_trgm_courses_#{column}") &&
       # if the temp index already exists, it means the new index failed; just let
       # the if_not_exists in the add below remove the invalid index
       !index_name_exists?(:courses, "index_trgm_courses_#{column}_old")
      rename_index :courses, "index_trgm_courses_#{column}", "index_trgm_courses_#{column}_old"
    end
    add_index :courses, "LOWER(#{column}) #{trgm}.#{type}_trgm_ops", using: type, name: :index_trgm_courses_course_code, algorithm: :concurrently, if_not_exists: true
    remove_index :courses, name: "index_trgm_courses_#{column}_old", algorithm: :concurrently, if_exists: true
  end

  def up
    return unless (trgm = connection.extension(:pg_trgm)&.schema)

    redo_trgm_index(:name, :gin, trgm)
    redo_trgm_index(:course_code, :gin, trgm)
    redo_trgm_index(:sis_source_id, :gin, trgm)
  end

  def down
    redo_trgm_index(:name, :gist, trgm)
    redo_trgm_index(:course_code, :gist, trgm)
    redo_trgm_index(:sis_source_id, :gist, trgm)
  end
end
