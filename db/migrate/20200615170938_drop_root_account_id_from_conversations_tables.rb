# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class DropRootAccountIdFromConversationsTables < ActiveRecord::Migration[5.2]
  tag :postdeploy

  def change
    remove_column :conversations, :root_account_id if column_exists?(:conversations, :root_account_id)
    remove_column :conversation_participants, :root_account_id if column_exists?(:conversation_participants, :root_account_id)
    remove_column :conversation_messages, :root_account_id if column_exists?(:conversation_messages, :root_account_id)
    remove_column :conversation_message_participants, :root_account_id if column_exists?(:conversation_message_participants, :root_account_id)
  end
end
