# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AddMigrationIdIndexToAttachments < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def change
    add_index :attachments,
              %i[context_id context_type migration_id],
              where: "migration_id IS NOT NULL",
              name: "index_attachments_on_context_and_migration_id",
              algorithm: :concurrently
  end
end
