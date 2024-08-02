# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup
  module DiscussionTypeUpdater
    def self.run
      DiscussionTopic.find_ids_in_ranges(batch_size: 10_000) do |start_at, end_at|
        DiscussionTopic
          .where(id: start_at..end_at)
          .active
          .where(discussion_type: "side_comment")
          .where(DiscussionEntry
            .select(1)
            .where("discussion_topic_id=discussion_topics.id")
            .where.not(parent_id: nil)
            .where.not(workflow_state: "deleted")
            .arel
            .exists)
          .in_batches.update_all(discussion_type: "threaded", updated_at: Time.now.utc)
      end
    end
  end
end
