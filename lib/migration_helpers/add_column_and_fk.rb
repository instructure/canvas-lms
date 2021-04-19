# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module MigrationHelpers::AddColumnAndFk
  def add_column_and_fk(table_name, column_name, foreign_table_name, if_not_exists: false)
    fk = connection.send(:foreign_key_name, table_name, :column => column_name)
    return if if_not_exists && connection.column_exists?(table_name, column_name)
    execute("ALTER TABLE #{connection.quote_table_name(table_name)} ADD COLUMN #{column_name} bigint CONSTRAINT #{fk} REFERENCES #{connection.quote_table_name(foreign_table_name)}(id)")
  end
end
