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
#

class RemoveCourseCodeCourseIndex < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    # Boolean index that is not used
    remove_index :courses, name: "index_trgm_courses_course_code", if_exists: true
  end

  def down
    if (trgm = connection.extension(:pg_trgm)&.schema)
      add_index :courses, "LOWER(course_code) #{trgm}.gist_trgm_ops", name: "index_trgm_courses_course_code", using: :gist, if_not_exists: true
    end
  end
end
