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

class AddSchemaMigrationsPrimaryKey < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # Rails 5 creates the schema_migrations table with a primary key in the first place;
    # so no need to convert it over
    return unless index_exists?(:schema_migrations, :version, name: 'unique_schema_migrations')
    execute("ALTER TABLE #{connection.quote_table_name('schema_migrations')} ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY USING INDEX unique_schema_migrations")
  end

  def self.down
    execute("ALTER TABLE #{connection.quote_table_name('schema_migrations')} DROP CONSTRAINT schema_migrations_pkey")
    add_index :schema_migrations, :version, :unique => true, :name => 'unique_schema_migrations'
  end
end
