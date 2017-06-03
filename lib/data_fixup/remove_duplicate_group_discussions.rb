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

module DataFixup::RemoveDuplicateGroupDiscussions
  def self.run
    bad_root_topics = DiscussionTopic.connection.select_rows(<<-SQL)
      SELECT context_id,context_type,root_topic_id
      FROM #{DiscussionTopic.quoted_table_name}
      WHERE root_topic_id IS NOT NULL 
      GROUP BY context_id,context_type,root_topic_id
      HAVING COUNT(*) > 1
    SQL

    need_refresh = []
    bad_root_topics.each do |context_id, context_type, root_topic_id|
      children = DiscussionTopic.
        where(:context_id => context_id, :context_type => context_type, :root_topic_id => root_topic_id).
        preload(:discussion_entries).
        sort_by{ |dt| dt.discussion_entries.length }

      # keep the active topic with the most entries
      deleted_children, active_children = children.partition{ |dt| dt.deleted? }
      keeper = active_children.pop

      # or the deleted topic if there aren't any active ones
      if keeper.blank?
        keeper = deleted_children.pop
      end

      # merge all posts on active duplicates to keeper
      to_move_entries = active_children.map(&:discussion_entries).flatten.compact
      if to_move_entries.present?
        DiscussionEntry.where(:id => to_move_entries).update_all(:discussion_topic_id => keeper)
        need_refresh << keeper
      end

      # unlink and delete all duplicate topics
      DiscussionTopic.where(:id => deleted_children + active_children).
          update_all(:root_topic_id => nil, :assignment_id => nil, :workflow_state => 'deleted')
    end

    need_refresh.each(&:update_materialized_view)
  end
end
