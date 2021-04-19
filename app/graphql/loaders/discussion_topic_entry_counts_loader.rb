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

class Loaders::DiscussionTopicEntryCountsLoader < GraphQL::Batch::Loader
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

  def counts_sql
    <<~SQL
      discussion_topic_id, COUNT(discussion_entries.id) AS replies,
      SUM(CASE WHEN discussion_entry_participants.workflow_state = 'read' THEN 1 ELSE 0 END) AS read
    SQL
  end

  def perform(discussion_topics)
    counts = DiscussionEntry.joins(join_sql)
      .where(discussion_entries: { workflow_state: 'active', discussion_topic_id: discussion_topics })
      .group('discussion_entries.discussion_topic_id')
      .select(counts_sql).index_by(&:discussion_topic_id)

    discussion_topics.each do |dt|
      topic_counts = {}
      topic_counts["replies_count"] = counts[dt.id]&.replies || 0
      topic_counts["unread_count"] = topic_counts["replies_count"] - (counts[dt.id]&.read || 0)
      fulfill(dt, topic_counts)
    end
  end
end
