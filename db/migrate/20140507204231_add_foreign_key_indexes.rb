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

class AddForeignKeyIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :content_exports, :attachment_id, algorithm: :concurrently
    add_index :content_migrations, :attachment_id, where: 'attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :content_migrations, :exported_attachment_id, where: 'exported_attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :content_migrations, :overview_attachment_id, where: 'overview_attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :discussion_entries, :attachment_id, where: 'attachment_id IS NOT NULL', algorithm: :concurrently
    add_index :discussion_topics, :attachment_id, where: 'attachment_id IS NOT NULL', algorithm: :concurrently
  end

  def self.down
    remove_index :content_exports, :attachment_id
    remove_index :content_migrations, :attachment_id
    remove_index :content_migrations, :exported_attachment_id
    remove_index :content_migrations, :overview_attachment_id
    remove_index :discussion_entries, :attachment_id
    remove_index :discussion_topics, :attachment_id
  end
end
