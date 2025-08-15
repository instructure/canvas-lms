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
  class AnnouncementsConnectionLoader < GraphQL::Batch::Loader
    def initialize(user:, limit: nil)
      super()
      @user = user
      @limit = limit
    end

    def perform(course_ids)
      # Batch load all announcements for the requested courses
      announcements = Announcement.active
                                  .where(context_type: "Course", context_id: course_ids)
                                  .joins(:context)
                                  .merge(Course.not_deleted)
                                  .order(created_at: :desc)

      # Apply limit if specified for dashboard widget
      announcements = announcements.limit(@limit) if @limit

      # Group announcements by course_id
      announcements_by_course = announcements.group_by(&:context_id)

      # Filter announcements based on user visibility rules
      course_ids.each do |course_id|
        course_announcements = announcements_by_course[course_id] || []

        # Apply section-specific scoping for each course's announcements
        if course_announcements.any?
          course = course_announcements.first.context
          course.shard.activate do
            scoped_announcements = DiscussionTopic::ScopedToSections.new(
              course,
              @user,
              course.discussion_topics.where(id: course_announcements.map(&:id))
            ).scope.to_a

            fulfill(course_id, scoped_announcements)
          end
        else
          fulfill(course_id, [])
        end
      end
    end
  end
end
