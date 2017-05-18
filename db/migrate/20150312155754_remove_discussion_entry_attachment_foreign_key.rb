#
# Copyright (C) 2015 - present Instructure, Inc.
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

class RemoveDiscussionEntryAttachmentForeignKey < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  # this foreign key constraint is problematic because discussion entry attachments belong to the user's shard,
  # not the course's shard
  def self.up
    # added in 20131231182559_add_foreign_keys13.rb
    remove_foreign_key_if_exists :discussion_entries, :attachments
    # (re-)added in 20140507204231_add_foreign_key_indexes.rb
    remove_index :discussion_entries, :attachment_id
  end

  def self.down
    # this will detach all cross-shard discussion entry attachments, which we did before we created the constraint originally
    DiscussionEntry.where("attachment_id IS NOT NULL AND NOT EXISTS (?)", Attachment.where("attachment_id=attachments.id")).update_all(attachment_id: nil)
    add_index :discussion_entries, :attachment_id, where: 'attachment_id IS NOT NULL', algorithm: :concurrently
    add_foreign_key_if_not_exists :discussion_entries, :attachments, delay_validation: true
  end
end
