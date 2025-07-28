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
  end

  def discussions_scope(course, user_id = nil, search_term = nil)
    scoped_user = user_id.nil? ? current_user : User.find_by(id: user_id)

    # If user_id was provided but user not found, return no discussions
    return DiscussionTopic.none if user_id.present? && scoped_user.nil?

    # Check if current user has permission to view discussions as the scoped user
    unless current_user.can_current_user_view_as_user(course, scoped_user)
      # Current user lacks permissions to view as the scoped user
      raise GraphQL::ExecutionError, "You do not have permission to view this course."
    end

    discussions = course.discussion_topics.active

    # Apply search term filter if provided
    if search_term.present?
      discussions = discussions.where(DiscussionTopic.wildcard(:title, search_term))
    end

    # Filter discussions based on user visibility rules
    DiscussionTopic::ScopedToUser.new(course, scoped_user, discussions).scope
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
    apply_discussion_order(
      discussions_scope(course, filter[:user_id], filter[:search_term])
    )
  end

  def apply_discussion_order(discussions)
    discussions.reorder(id: :asc)
  end
end
