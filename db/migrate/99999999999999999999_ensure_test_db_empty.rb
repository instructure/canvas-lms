# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class EnsureTestDbEmpty < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def self.runnable?
    Rails.env.test?
  end

  def up
    non_empty_tables = connection.tables.select do |t|
      connection.select_value("SELECT COUNT(*) FROM #{connection.quote_table_name(t)}") > 0
    end
    non_empty_tables.delete(ActiveRecord::Base.schema_migrations_table_name)
    non_empty_tables.delete(ActiveRecord::Base.internal_metadata_table_name)
    non_empty_tables.delete(Shard.table_name)
    non_empty_tables.delete(Account.table_name)
    non_empty_tables << Account.table_name if Account.where.not(id: 0).exists?

    # If you're seeing this error, you've created a migration or modified a non-migration method
    # called by a hook that creates data. Go look in the mentioned table to see what data
    # was accidentally created. The test database should be completely empty after migrations run
    # with the exception of the core tables mentioned above, and a single row in the accounts
    # table for the dummy root account. You can test locally by running
    # `RAILS_ENV=test bin/rake db:test:reset`
    raise "Test database is not empty! Tables with data: #{non_empty_tables.join(", ")}" unless non_empty_tables.empty?
  end
end
