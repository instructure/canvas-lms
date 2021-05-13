# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

class DiscussionTopicUsersController < ApplicationController
  include SubmittableHelper
  include Api::V1::Conversation

  before_action :require_context_and_read_access
  before_action :require_topic_and_read_access

  # @argument search [String]
  #   Search terms used for matching users (e.g. "bob smith"). If
  #   multiple terms are given (separated via whitespace), only results matching
  #   all terms will be returned.
  #
  # @example_response
  #   [
  #     {"id": "group_1", "name": "the group", "type": "context", "user_count": 3},
  #     {"id": 2, "name": "greg", "full_name": "greg jones", "common_courses": {}, "common_groups": {"1": ["Member"]}}
  #   ]
  #
  # @response_field id The unique identifier for the user/context. For
  #   groups/courses, the id is prefixed by "group_"/"course_" respectively.
  # @response_field name The name of the context or short name of the user
  # @response_field full_name Only set for users. The full name of the user
  # @response_field avatar_url Avatar image url for the user/context
  def search
    calculator = ::MessageableUser::Calculator.new(@current_user)
    users = calculator.search_messageable_users(context: @topic.context_code, search: params[:search])
    users = Api.paginate(users, self, messageable_user_pagination_url)
      .map { |user| conversation_user_json(user, @current_user, session) }
    render json: users
  end

  protected
  def require_topic_and_read_access
    @topic = @context.all_discussion_topics.active.find(params[:topic_id])
    authorized_action(@topic, @current_user, :read) && check_differentiated_assignments(@topic)
  end

  def messageable_user_pagination_url
    if @context.is_a? Course
      api_v1_course_discussion_topics_url(@context)
    else
      api_v1_group_discussion_topics_url(@context)
    end
  end
end