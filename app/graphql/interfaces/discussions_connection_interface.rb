# frozen_string_literal: true

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

module Interfaces::DiscussionsConnectionInterface
  include Interfaces::BaseInterface

  class DiscussionFilterInputType < Types::BaseInputObject
    graphql_name "DiscussionFilter"
    argument :user_id, ID, <<~MD, required: false
      only return discussions for the given user. Defaults to
      the current user.
    MD
    argument :search_term, String, <<~MD, required: false
      only return discussions whose title matches this search term
    MD
    argument :is_announcement, Boolean, <<~MD, required: false
      only return discussions that are announcements (true) or
      regular discussions (false). If not provided, returns both.
    MD
  end

  def discussions_scope(course, user_id = nil, search_term = nil, is_announcement = nil)
    scoped_user = user_id.nil? ? current_user : User.find_by(id: user_id)

    # If user_id was provided but user not found, return no discussions
    return DiscussionTopic.none if user_id.present? && scoped_user.nil?

    # Check if current user has permission to view discussions as the scoped user
    unless current_user.can_current_user_view_as_user(course, scoped_user)
      # Current user lacks permissions to view as the scoped user
      raise GraphQL::ExecutionError, "You do not have permission to view this course."
    end

    discussions = if is_announcement == true
                    # For announcements, use the same logic as /courses/X/announcements page
                    # Start with active_announcements scope (just workflow_state <> 'deleted')
                    course.active_announcements
                  else
                    course.discussion_topics.active
                  end

    # Apply announcement filter for non-announcement-specific queries
    if is_announcement == false
      discussions = discussions.where(type: ["DiscussionTopic", nil])
    end

    # Apply search term filter if provided
    if search_term.present?
      discussions = discussions.where(DiscussionTopic.wildcard(:title, search_term))
    end

    if is_announcement == true
      # Apply the exact same filtering logic as DiscussionTopicsController#index for announcements
      # For non-admins, apply time constraints just like the official announcements page
      unless course.grants_any_right?(current_user, :manage, :read_as_admin)
        current_time = Time.now.utc
        discussions = discussions.active.where(
          "((unlock_at IS NULL AND delayed_post_at IS NULL) OR (unlock_at<? OR delayed_post_at<?)) AND (lock_at IS NULL OR lock_at>?)",
          current_time,
          current_time,
          current_time
        )
      end

      # Apply section scoping for announcements (matches official logic)
      course.shard.activate do
        discussions = DiscussionTopic::ScopedToSections.new(course, scoped_user, discussions).scope
      end
    else
      # For regular discussions, use the standard user scoping
      discussions = DiscussionTopic::ScopedToUser.new(course, scoped_user, discussions).scope
    end

    discussions
  end

  field :discussions_connection,
        ::Types::DiscussionType.connection_type,
        <<~MD,
          returns a list of discussions.
        MD
        null: true do
    argument :filter, DiscussionFilterInputType, required: false
  end

  def discussions_connection(course:, filter: {})
    discussions = discussions_scope(
      course,
      filter[:user_id],
      filter[:search_term],
      filter[:is_announcement]
    )
    apply_discussion_order(discussions, filter[:is_announcement])
  end

  def apply_discussion_order(discussions, is_announcement = nil)
    if is_announcement == true
      # Sort announcements by creation date descending for dashboard widget
      discussions.reorder(created_at: :desc)
    else
      # Keep existing behavior for regular discussions
      discussions.reorder(id: :asc)
    end
  end
end
