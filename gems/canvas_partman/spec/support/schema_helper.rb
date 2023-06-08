# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module CanvasPartmanTest::SchemaHelper
  class << self
    def create_table(table_name, opts = {}, &)
      ActiveRecord::Migration.create_table(table_name, **opts, &)
    end

    def table_exists?(table_name)
      ActiveRecord::Base.connection.table_exists?(table_name)
    end

    def drop_table(table_name, opts = {})
      if table_exists?(table_name)
        # `drop_table` doesn't really accept any options, so cascade must be
        # done manually.
        #
        # see http://apidock.com/rails/ActiveRecord/ConnectionAdapters/SchemaStatements/drop_table
        if opts[:cascade]
          ActiveRecord::Base.connection.execute <<~SQL.squish
            DROP TABLE #{table_name}
            CASCADE
          SQL
        else
          ActiveRecord::Migration.drop_table(table_name)
        end
      end
    end
  end
end

SchemaHelper = CanvasPartmanTest::SchemaHelper
