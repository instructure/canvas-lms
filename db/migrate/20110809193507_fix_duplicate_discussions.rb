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

class FixDuplicateDiscussions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    DiscussionTopic.transaction do
      duplicate_topics = DiscussionTopic.
        select([:old_assignment_id, :context_id, :context_type]).
        where("old_assignment_id IS NOT NULL AND workflow_state <> 'deleted' AND root_topic_id IS NULL AND context_type='Course'").
        group('old_assignment_id, context_id, context_type HAVING COUNT(*) > 1').to_a

      duplicate_topics.each do |topic|
        duplicates = DiscussionTopic.
          where("context_id=? AND context_type=? AND old_assignment_id=? AND workflow_state<>'deleted' AND root_topic_id is null",
                topic.context_id, topic.context_type, topic.old_assignment_id).
          order('updated_at DESC').to_a
        to_keep = duplicates.shift

        DiscussionEntry.where(:discussion_topic_id => duplicates).update_all(:discussion_topic_id => to_keep)
        DiscussionTopic.where(:root_topic_id => duplicates).update_all(:root_topic_id => to_keep)
        DiscussionTopic.delete(duplicates)
      end
    end
  end

  def self.down
  end
end
