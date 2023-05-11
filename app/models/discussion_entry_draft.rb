# frozen_string_literal: true

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
#

class DiscussionEntryDraft < ActiveRecord::Base
  belongs_to :discussion_topic, inverse_of: :discussion_entry_drafts
  belongs_to :discussion_entry, inverse_of: :discussion_entry_drafts
  belongs_to :attachment, inverse_of: :discussion_entry_drafts
  belongs_to :user, inverse_of: :discussion_entry_drafts

  def self.upsert_draft(user:, topic:, message:, entry: nil, parent: nil, attachment: nil, reply_preview: false)
    insert_columns = %w[user_id
                        discussion_topic_id
                        discussion_entry_id
                        root_entry_id
                        parent_id
                        attachment_id
                        message
                        include_reply_preview
                        updated_at
                        created_at]

    topic.shard.activate do
      insert_values = []
      insert_values << user.id
      insert_values << topic.id
      insert_values << entry&.id
      insert_values << (parent&.root_entry_id || parent&.id)
      insert_values << parent&.id
      insert_values << attachment&.id
      insert_values << message
      insert_values << reply_preview
      insert_values = insert_values.map { |iv| connection.quote(iv) }

      conflict_condition = "(discussion_topic_id, user_id) WHERE root_entry_id IS NULL AND discussion_entry_id IS NULL"
      conflict_condition = "(root_entry_id, user_id) WHERE discussion_entry_id IS NULL" if parent
      conflict_condition = "(discussion_entry_id, user_id)" if entry

      update_columns = %w[message include_reply_preview]
      update_columns << "parent_id" if parent
      update_columns << "attachment" if attachment

      update_values = []
      update_values << message
      update_values << reply_preview
      update_values << parent.id if parent
      update_values << attachment.id if attachment
      update_values = update_values.map { |uv| connection.quote(uv) }

      update_statement = "#{update_columns.zip(update_values).map { |a| a.join("=") }.join(",")},updated_at=NOW()"

      upsert_sql = <<~SQL.squish
          INSERT INTO #{quoted_table_name}
                      (#{insert_columns.join(",")})
               VALUES (#{insert_values.join(",")},NOW(),NOW())
          ON CONFLICT #{conflict_condition}
        DO UPDATE SET #{update_statement}
            RETURNING id
      SQL

      connection.select_values(upsert_sql)
    end
  end
end
