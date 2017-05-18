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

class MessageAttachmentsAndMediaObjects < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversations, :has_attachments, :boolean
    add_column :conversations, :has_media_objects, :boolean
    add_column :conversation_participants, :has_attachments, :boolean
    add_column :conversation_participants, :has_media_objects, :boolean
  end

  def self.down
    remove_column :conversations, :has_attachments
    remove_column :conversations, :has_media_objects
    remove_column :conversation_participants, :has_attachments
    remove_column :conversation_participants, :has_media_objects
  end
end
