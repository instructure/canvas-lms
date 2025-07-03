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

module Loaders
  module DiscussionTopicLoaders
    class CanUnpublishLoader < GraphQL::Batch::Loader
      def initialize(context)
        super()
        @context = context
      end

      def perform(discussion_topic_ids)
        # Load discussion topics with their assignments
        discussion_topics = DiscussionTopic.where(id: discussion_topic_ids).to_a
        ActiveRecord::Associations.preload(discussion_topics, :assignment)
        discussion_topics = discussion_topics.index_by(&:id)

        # Get assignment IDs for submission checking
        assignment_ids = discussion_topics.values.filter_map(&:assignment_id)

        # Batch check for assignments with student submissions (including sub-assignments)
        assmnt_ids_with_subs = if assignment_ids.any?
                                 (Assignment.assignment_ids_with_submissions(assignment_ids) + Assignment.assignment_ids_with_sub_assignment_submissions(assignment_ids)).uniq
                               else
                                 []
                               end
        assignments_with_subs = Set.new(assmnt_ids_with_subs)

        # Get student entry data for non-graded discussions
        student_ids = @context.all_real_student_enrollments.select(:user_id)
        non_graded_topics = discussion_topics.values.reject(&:assignment_id)

        if non_graded_topics.any?
          # Check for student entries in non-graded discussions
          topics_with_entries = DiscussionEntry.active
                                               .joins(:discussion_topic)
                                               .where(discussion_topic: non_graded_topics, user_id: student_ids)
                                               .distinct
                                               .pluck(:discussion_topic_id)
          topics_with_entries_set = Set.new(topics_with_entries)
        else
          topics_with_entries_set = Set.new
        end

        # Batch check can_unpublish for all topics
        discussion_topic_ids.each do |id|
          discussion_topic = discussion_topics[id]
          if discussion_topic
            can_unpublish = if discussion_topic.assignment
                              assignments_with_subs.exclude?(discussion_topic.assignment.id)
                            else
                              topics_with_entries_set.exclude?(discussion_topic.id)
                            end
            fulfill(id, can_unpublish)
          else
            fulfill(id, true) # Default to true if topic doesn't exist
          end
        end
      end
    end
  end
end
