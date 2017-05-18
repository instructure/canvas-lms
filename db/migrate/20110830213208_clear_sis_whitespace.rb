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

class ClearSisWhitespace < ActiveRecord::Migration[4.2]
  tag :predeploy


  def self.clear(table, *cols)
    cols = cols.map{|col|" #{col} = TRIM(#{col})"}.join(',')
    update("UPDATE #{connection.quote_table_name(table)} SET #{cols}")
  end

  def self.up
    clear(:pseudonyms, :unique_id, :sis_source_id, :sis_user_id)
    clear(:users, :name, :sis_name)
    clear(:enrollment_terms, :name, :sis_name, :sis_source_id)
    clear(:course_sections, :name, :sis_name, :sis_source_id)
    clear(:groups, :name, :sis_name, :sis_source_id)
    clear(:courses, :name, :sis_name, :sis_source_id, :course_code, :sis_course_code)
    clear(:abstract_courses, :name, :sis_name, :sis_source_id, :short_name, :sis_course_code)
    clear(:course_sections, :name, :sis_name, :sis_source_id)
    clear(:enrollments, :sis_source_id)
    clear(:accounts, :name, :sis_name, :sis_source_id)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
