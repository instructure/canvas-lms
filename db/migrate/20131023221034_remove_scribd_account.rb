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

class RemoveScribdAccount < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    drop_table :scribd_accounts
    remove_column :attachments, :scribd_account_id
    remove_column :attachments, :scribd_user
  end

  def self.down
    create_table "scribd_accounts", :force => true do |t|
      t.integer  "scribdable_id", :limit => 8
      t.string   "scribdable_type"
      t.string   "uuid"
      t.string   "workflow_state"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "scribd_accounts", ["scribdable_id", "scribdable_type"], :name => "index_scribd_accounts_on_scribdable_id_and_scribdable_type"

    add_column :attachments, :scribd_account_id, :integer, :limit => 8
    add_column :attachments, :scribd_user, :string

  end
end
