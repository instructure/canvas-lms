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

# No special imports needed for compact

class Loaders::ModuleItemMasterCourseRestrictionsLoader < GraphQL::Batch::Loader
  def initialize(current_user)
    super()
    @current_user = current_user
  end

  def perform(content_tags)
    GuardRail.activate(:secondary) do
      # Group content tags by context (course) to efficiently process them
      content_tags_by_context = content_tags.group_by(&:context_id)

      content_tags_by_context.each do |context_id, tags|
        context = Course.find_by(id: context_id)
        next unless context

        # Check if this is a master or child course
        is_child_course = MasterCourses::ChildSubscription.is_child_course?(context)
        is_master_course = MasterCourses::MasterTemplate.is_master_course?(context)

        # If not a master or child course, fulfill with nil for all tags in this context
        unless is_child_course || is_master_course
          tags.each do |tag|
            fulfill(tag, nil)
          end
          next
        end

        # Only process content tags with supported content types
        valid_tags = tags.select { |tag| %w[Assignment Attachment DiscussionTopic Quizzes::Quiz WikiPage].include?(tag.content_type) }
        invalid_tags = tags - valid_tags

        # For any non-supported content types, fulfill with nil
        invalid_tags.each do |tag|
          fulfill(tag, nil)
        end

        # If no valid tags, skip to next context
        next if valid_tags.empty?

        # Get tag IDs for fetching restrictions
        tag_ids = valid_tags.map(&:id)

        # Fetch restrictions based on whether this is a master or child course
        restriction_info = if is_child_course
                             MasterCourses::MasterContentTag.fetch_module_item_restrictions_for_child(tag_ids)
                           else
                             MasterCourses::MasterContentTag.fetch_module_item_restrictions_for_master(tag_ids)
                           end

        # Process each valid tag
        valid_tags.each do |tag|
          restrictions = restriction_info[tag.id]
          fulfill(tag, restrictions)
        end
      end

      # For any content tags that weren't fulfilled, fulfill with nil
      content_tags.each do |tag|
        fulfill(tag, nil) unless fulfilled?(tag)
      end
    end
  end
end
