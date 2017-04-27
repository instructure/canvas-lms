#
# Copyright (C) 2012 - present Instructure, Inc.
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

class SubmissionCommentsInConversations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_messages, :asset_id, :integer, :limit => 8
    add_column :conversation_messages, :asset_type, :string
    if adapter_name == 'PostgreSQL'
      execute("CREATE INDEX index_conversation_messages_on_asset_id_and_asset_type ON #{ConversationMessage.quoted_table_name} (asset_id, asset_type) WHERE asset_id IS NOT NULL")
    else
      add_index :conversation_messages, [:asset_id, :asset_type]
    end
  end

  def self.down
    remove_column :conversation_messages, :asset_id
    remove_column :conversation_messages, :asset_type
  end
end
