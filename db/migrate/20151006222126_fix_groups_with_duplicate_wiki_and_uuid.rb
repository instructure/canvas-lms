#
# Copyright (C) 2015 - present Instructure, Inc.
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

class FixGroupsWithDuplicateWikiAndUuid < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::FixGroupsWithDuplicateWikiAndUuid.run

    # There are a very small number of groups with no uuid
    [Group, GroupMembership].each do |klass|
      klass.where(uuid: nil).find_each do |item|
        klass.where(id: item).update_all(
          uuid: CanvasSlug.generate_securish_uuid,
          updated_at: Time.now.utc
        )
      end
    end

    change_column_null :groups, :uuid, false
    change_column_null :group_memberships, :uuid, false

    add_index :groups, :uuid, unique: true, algorithm: :concurrently
    add_index :group_memberships, :uuid, unique: true, algorithm: :concurrently
  end

  def down
    change_column_null :groups, :uuid, true
    change_column_null :group_memberships, :uuid, true

    remove_index :groups, :uuid
    remove_index :group_memberships, :uuid
  end
end
