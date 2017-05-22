#
# Copyright (C) 2011 - present Instructure, Inc.
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

class CreateAccessTokens < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :access_tokens do |t|
      t.integer :developer_key_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.string :token
      t.datetime :last_used_at
      t.datetime :expires_at
      t.string :purpose
      t.timestamps null: true
    end
    add_index :access_tokens, [:token], :unique => true

    # developer_key.user_id was a string instead of an integer
    add_column :developer_keys, :user_id_int, :integer, :limit => 8
    if connection.adapter_name =~ /\Apostgres/i
      update <<-SQL
        UPDATE #{DeveloperKey.quoted_table_name} SET user_id_int = CAST(user_id AS INTEGER) WHERE user_id IS NOT NULL
      SQL
    else
      update <<-SQL
        UPDATE #{DeveloperKey.quoted_table_name} SET user_id_int = CAST(user_id AS UNSIGNED) WHERE user_id IS NOT NULL
      SQL
    end
    remove_column :developer_keys, :user_id
    rename_column :developer_keys, :user_id_int, :user_id

    add_column :developer_keys, :name, :string
  end

  def self.down
    drop_table :access_tokens
    change_column :developer_keys, :user_id, :string
    remove_column :developer_keys, :name
  end
end
