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

class AddContextIdIdIndexContentMigrations < ActiveRecord::Migration[6.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :content_migrations, [:context_id, :id], algorithm: :concurrently, name: "index_content_migrations_on_context_id_and_id_no_clause", if_not_exists: true
    # The above index will cover all of the same queries, and having both is just additional write burden for the db,
    # so we'll remove the context_id index.
    remove_index :content_migrations, :context_id, if_exists: true
  end
end
