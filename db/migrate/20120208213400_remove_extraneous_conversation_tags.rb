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

class RemoveExtraneousConversationTags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::RemoveExtraneousConversationTags.send_later_if_production(:run)

    # incidentally, when someone deletes all the messages from their CP, its
    # tags should get cleared out, but a bug prevented that from happening
    # (that's also fixed in this commit).
    ConversationParticipant.where(last_message_at: nil, message_count: 0).where("tags<>''").update_all(tags: '')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
