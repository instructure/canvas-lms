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

class FixUserMergeConversations < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    disable_ddl_transaction!

    # remove any duplicate CP's, possibly fixing private conversation hashes
    # (which may merge it with another conversation)
    ConversationParticipant.find_by_sql(<<-SQL).
      SELECT conversation_participants.*
      FROM #{ConversationParticipant.quoted_table_name}, (
        SELECT MIN(id) AS id, user_id, conversation_id
        FROM #{ConversationParticipant.quoted_table_name}
        GROUP BY user_id, conversation_id
        HAVING COUNT(*) > 1
        ORDER BY conversation_id
      ) cps2keep
      WHERE conversation_participants.user_id = cps2keep.user_id
        AND conversation_participants.conversation_id = cps2keep.conversation_id
        AND conversation_participants.id <> cps2keep.id
    SQL
    each do |cp|
      cp.destroy
      cp.conversation.regenerate_private_hash! if cp.private?
    end

    # there may be a bunch more private conversations with the wrong private
    # hash, and there's not a reliable way to figure out which ones those are
    # in sql alone (unless you have a sha1 method for postgres), so
    # we just walk them all out of band and make sure they're right (this may
    # also merge some private conversations in the process)
    Conversation.where("private_hash IS NOT NULL").pluck(:id).each_slice(1000) do |ids|
      Conversation.send_later_if_production_enqueue_args(:batch_regenerate_private_hashes!, {
        :priority => Delayed::LOWER_PRIORITY,
        :max_attempts => 1,
        :strand => "regenerate_conversation_private_hashes"
      }, ids)
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
