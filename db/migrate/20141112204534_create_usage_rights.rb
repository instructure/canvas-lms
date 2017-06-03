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

class CreateUsageRights < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :usage_rights do |t|
      t.integer :context_id, :limit => 8, null: false
      t.string :context_type, null: false
      t.string :use_justification, null: false
      t.string :license, null: false
      t.text :legal_copyright
    end
    add_index :usage_rights, [:context_id, :context_type], name: 'usage_rights_context_idx'

    add_column :attachments, :usage_rights_id, :integer, :limit => 8
    add_foreign_key :attachments, :usage_rights, column: :usage_rights_id
  end

  def down
    remove_foreign_key :attachments, column: :usage_rights_id
    remove_column :attachments, :usage_rights_id
    drop_table :usage_rights
  end
end

