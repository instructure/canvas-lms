# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# This is a custom loader to perform one query for a group of discussion topics,
# or root_discussion_entries,
class Loaders::DiscussionEntryCountsLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    @current_user = current_user
  end

  def join_sql
    <<~SQL
      LEFT OUTER JOIN #{DiscussionEntryParticipant.quoted_table_name} ON
        discussion_entries.id = discussion_entry_participants.discussion_entry_id
        AND discussion_entry_participants.user_id = '#{@current_user.id}'
    SQL
  end

  def counts_sql(id_string)
    <<~SQL
      #{id_string}, COUNT(discussion_entries.id) AS replies,
      SUM(CASE WHEN discussion_entry_participants.workflow_state = 'read' THEN 1 ELSE 0 END) AS read
    SQL
  end

  def perform(objects)
    object_id = object_id_string(objects.first)
    counts = DiscussionEntry.joins(join_sql)
      .where(discussion_entries: object_specific_hash(objects))
      .group("discussion_entries.#{object_id}")
      .select(counts_sql(object_id)).index_by(&object_id.to_sym)

    objects.each do |object|
      object_counts = {}
      object_counts["replies_count"] = counts[object.id]&.replies || 0
      object_counts["unread_count"] = object_counts["replies_count"] - (counts[object.id]&.read || 0)
      fulfill(object, object_counts)
    end
  end

  def object_specific_hash(objects)
    if objects.first.is_a?(DiscussionTopic)
      { discussion_topic_id: objects }
    elsif objects.first.is_a?(DiscussionEntry)
      { root_entry_id: objects }
    end
  end

  def object_id_string(object)
    if object.is_a?(DiscussionTopic)
      'discussion_topic_id'
    elsif object.is_a?(DiscussionEntry)
      'root_entry_id'
    end
  end
end
