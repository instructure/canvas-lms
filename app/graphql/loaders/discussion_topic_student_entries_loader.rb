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
#

# Preloader to batch-check if discussion topics have student entries
# Used to optimize the can_unpublish? check and eliminate N+1 queries
class Loaders::DiscussionTopicStudentEntriesLoader < GraphQL::Batch::Loader
  def initialize(course:)
    super()
    @course = course
  end

  def perform(discussion_topics)
    # Get all student user IDs for this course
    student_ids = @course.all_real_student_enrollments.select(:user_id)

    # Group topics by whether they are group discussions or regular discussions
    regular_topics = discussion_topics.reject(&:for_group_discussion?)
    group_topics = discussion_topics.select(&:for_group_discussion?)

    # Hash to store results: topic_id => has_student_entries (boolean)
    results = {}

    # Handle regular discussion topics
    if regular_topics.any?
      topic_ids = regular_topics.map(&:id)

      # Single query to check which topics have student entries
      topics_with_entries = DiscussionEntry.active
                                           .where(discussion_topic_id: topic_ids)
                                           .where(user_id: student_ids)
                                           .distinct
                                           .pluck(:discussion_topic_id)
                                           .to_set

      regular_topics.each do |topic|
        results[topic.id] = topics_with_entries.include?(topic.id)
      end
    end

    # Handle group discussion topics
    if group_topics.any?
      group_topics.each do |topic|
        # For group discussions, check child topics
        child_topic_ids = topic.child_topics.pluck(:id)

        if child_topic_ids.any?
          has_entries = DiscussionEntry.active
                                       .joins(:discussion_topic)
                                       .where(discussion_topic_id: child_topic_ids)
                                       .where(user_id: student_ids)
                                       .exists?

          results[topic.id] = has_entries
        else
          results[topic.id] = false
        end
      end
    end

    # Fulfill each topic with its result
    discussion_topics.each do |topic|
      fulfill(topic, results[topic.id] || false)
    end
  end
end
