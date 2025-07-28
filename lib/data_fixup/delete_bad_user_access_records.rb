# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  module DeleteBadUserAccessRecords
    # Due to a bug in setting the context for GraphQL endpoints,
    # some user access records on group discussions have been assigned to
    # courses, resulting in blank rows on the user access page.
    #
    # This query will clean up these faulty records the following way:
    #   - iterate through group discussions in batches
    #   - find the user access records
    #   - which belong to the discussion participants
    #   - and the user access context is set to course
    #
    # This way, the query can utilize
    # index_asset_user_accesses_on_user_id_and_asset_code, making the execution
    # significantly faster than iterating though user accesses directly.
    class << self
      def run
        DiscussionTopic.find_ids_in_ranges(batch_size: 10_000) do |min, max|
          AssetUserAccess
            .joins(<<~SQL.squish)
              INNER JOIN #{DiscussionTopicParticipant.quoted_table_name}
                ON discussion_topic_participants.user_id = asset_user_accesses.user_id
                AND asset_user_accesses.asset_code = concat('discussion_topic_', discussion_topic_participants.discussion_topic_id)
              INNER JOIN #{DiscussionTopic.quoted_table_name}
                ON discussion_topics.id = discussion_topic_participants.discussion_topic_id
            SQL
            .where(discussion_topics: { context_type: "Group" })
            .where(discussion_topics: { id: min..max })
            .where(asset_user_accesses: { context_type: "Course" })
            .delete_all
        end
      end
    end
  end
end
