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

class AddConversationBatches < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :conversation_batches do |t|
      t.string :workflow_state
      t.integer :user_id, :limit => 8
      t.text :recipient_ids
      t.integer :root_conversation_message_id, :limit => 8
      t.text :conversation_message_ids
      t.text :tags
      t.timestamps null: true
    end
    add_index :conversation_batches, [:user_id, :workflow_state]
  end

  def self.down
    drop_table :conversation_batches
  end
end
