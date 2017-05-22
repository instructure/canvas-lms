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

module DataFixup::RemoveExtraneousConversationTags
  def self.run
    # non-deleted CPs in a private conversation should usually have the same
    # tags. if they don't, they may need fixing (not necessarily ... the tags
    # are a function of the non-deleted messages).
    conditions = <<-COND
      private_hash IS NOT NULL AND (
        SELECT COUNT(DISTINCT tags)
        FROM #{ConversationParticipant.quoted_table_name}
        WHERE conversation_id = conversations.id
      ) > 1
    COND
    Conversation.where(conditions).find_each do |c|
      fix_private_conversation!(c)
    end
  end

  def self.fix_private_conversation!(c)
    return if c.tags.empty? || !c.private?
    allowed_tags = c.current_context_strings(1)
    Conversation.transaction do
      c.lock!
      c.update_attribute :tags, c.tags & allowed_tags
      c.conversation_participants.preload(:user).each do |cp|
        next unless cp.user
        tags_to_remove = cp.tags - c.tags
        next if tags_to_remove.empty?
        cp.update_attribute :tags, cp.tags & c.tags
        cp.conversation_message_participants.tagged(*tags_to_remove).each do |cmp|
          new_tags = cmp.tags & c.tags
          new_tags = cp.tags if new_tags.empty?
          cmp.update_attribute :tags, new_tags
        end
      end
    end
  end
end
