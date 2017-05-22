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

class ConversationsHasAttachmentsNotNull < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    [:conversations, :conversation_participants].each do |table|
      [:has_attachments, :has_media_objects].each do |column|
        change_column_null table, column, false, false
        change_column_default table, column, false
      end
    end
  end

  def self.down
    [:conversations, :conversation_participants].each do |table|
      [:has_attachments, :has_media_objects].each do |column|
        change_column_null table, column, true
        change_column_default table, column, nil
      end
    end
  end
end
