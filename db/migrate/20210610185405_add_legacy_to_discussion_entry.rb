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

class AddLegacyToDiscussionEntry < ActiveRecord::Migration[6.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    new_pg = connection.postgresql_version >= 110000
    defaults = new_pg ? { default: true, null: false } : {}
    add_column :discussion_entries, :legacy, :boolean, if_not_exists: true, **defaults

    unless new_pg
      change_column_default :discussion_entries, :legacy, true
      DataFixup::BackfillNulls.run(DiscussionEntry, [:legacy], default_value: true)
      change_column_null :discussion_entries, :legacy, false
    end

    add_index :discussion_entries, :legacy, where: "legacy", algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_column :discussion_entries, :legacy
  end
end
