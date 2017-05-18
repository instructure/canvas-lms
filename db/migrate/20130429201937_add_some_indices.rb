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

class AddSomeIndices < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :conversation_message_participants, :conversation_message_id, :name => "index_conversation_message_participants_on_message_id", :algorithm => :concurrently
    add_index :pseudonyms, :sis_communication_channel_id, :algorithm => :concurrently
  end

  def self.down
    remove_index :conversation_message_participants, :name => "index_conversation_message_participants_on_message_id"
    remove_index :pseudonyms, :sis_communication_channel_id
  end
end
