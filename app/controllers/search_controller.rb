# frozen_string_literal: true

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
#

# @API Search

class SearchController < ApplicationController
  include SearchHelper
  include Api::V1::Conversation

  before_action :require_user, except: [:all_courses]
  before_action :get_context, except: :recipients

  def rubrics
    contexts = begin
      @current_user.management_contexts
    rescue
      []
    end
    res = []
    contexts.each do |context|
      res += begin
        context.rubrics
      rescue
        []
      end
    end
    res += Rubric.publicly_reusable.matching(params[:q])
    res = res.select { |r| r.title.downcase.match(params[:q].downcase) }
    render json: res
  end

  # @API Find recipients
  # Find valid recipients (users, courses and groups) that the current user
  # can send messages to. The /api/v1/search/recipients path is the preferred
  # endpoint, /api/v1/conversations/find_recipients is deprecated.
  #
  # Pagination is supported.
  #
  # @argument search [String]
  #   Search terms used for matching users/courses/groups (e.g. "bob smith"). If
  #   multiple terms are given (separated via whitespace), only results matching
  #   all terms will be returned.
  #
  # @argument context [String]
  #   Limit the search to a particular course/group (e.g. "course_3" or "group_4").
  #
  # @argument exclude[] [String]
  #   Array of ids to exclude from the search. These may be user ids or
  #   course/group ids prefixed with "course_" or "group_" respectively,
  #   e.g. exclude[]=1&exclude[]=2&exclude[]=course_3
  #
  # @argument type [String, "user"|"context"]
  #   Limit the search just to users or contexts (groups/courses).
  #
  # @argument user_id [Integer]
  #   Search for a specific user id. This ignores the other above parameters,
  #   and will never return more than one result.
  #
  # @argument from_conversation_id [Integer]
  #   When searching by user_id, only users that could be normally messaged by
  #   this user will be returned. This parameter allows you to specify a
  #   conversation that will be referenced for a shared context -- if both the
  #   current user and the searched user are in the conversation, the user will
  #   be returned. This is used to start new side conversations.
  #
  # @argument permissions[] [String]
  #   Array of permission strings to be checked for each matched context (e.g.
  #   "send_messages"). This argument determines which permissions may be
  #   returned in the response; it won't prevent contexts from being returned if
  #   they don't grant the permission(s).
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
  # @response_field type ["context"|"course"|"section"|"group"|"user"|null]
  #   Type of recipients to return, defaults to null (all). "context"
  #   encompasses "course", "section" and "group"
  # @response_field types[] Array of recipient types to return (see type
  #   above), e.g. types[]=user&types[]=course
  # @response_field user_count Only set for contexts, indicates number of
  #   messageable users
  # @response_field common_courses Only set for users. Hash of course ids and
  #   enrollment types for each course to show what they share with this user
  # @response_field common_groups Only set for users. Hash of group ids and
  #   enrollment types for each group to show what they share with this user
  # @response_field permissions[] Only set for contexts. Mapping of requested
  #   permissions that the context grants the current user, e.g.
  #   { send_messages: true }
  def recipients
    GuardRail.activate(:secondary) do
      # admins may not be able to see the course listed at the top level (since
      # they aren't enrolled in it), but if they search within it, we want
      # things to work, so we set everything up here

      if params[:user_id]
        params[:user_id] = api_find(User, params[:user_id]).id
      end

      # null out the context param if it's invalid, but leave it as is
      # otherwise (to preserve e.g. `_students` suffix)
      search_context = AddressBook.load_context(params[:context])
      params[:context] = nil unless search_context

      permissions = params[:permissions] || []
      permissions << :send_messages if params[:messageable_only]
      load_all_contexts(context: search_context, permissions:)

      params[:per_page] = nil if params[:per_page].to_i <= 0

      recipients = []
      if params[:user_id]
        known = @current_user.address_book.known_user(
          params[:user_id],
          context: params[:context],
          conversation_id: params[:from_conversation_id]
        )
        recipients << known if known
      elsif params[:context] || params[:search]
        collections = search_contexts_and_users(params)

        recipients = BookmarkedCollection.concat(*collections)
        recipients = Api.paginate(recipients, self, api_v1_search_recipients_url)
      end

      render json: conversation_recipients_json(recipients, @current_user, session)
    end
  end

  # @API List all courses
  # A paginated list of all courses visible in the public index
  #
  # @argument search [String]
  #   Search terms used for matching users/courses/groups (e.g. "bob smith"). If
  #   multiple terms are given (separated via whitespace), only results matching
  #   all terms will be returned.
  #
  # @argument public_only [Optional, Boolean]
  #   Only return courses with public content. Defaults to false.
  #
  # @argument open_enrollment_only [Optional, Boolean]
  #   Only return courses that allow self enrollment. Defaults to false.
  #
  def all_courses
    return render_unauthorized_action unless @domain_root_account.enable_course_catalog?

    @courses = Course.where(root_account_id: @domain_root_account)
                     .where(indexed: true)
                     .where(workflow_state: "available")
                     .order("created_at")
    @search = params[:search]
    if @search.present?
      @courses = @courses.where(@courses.wildcard("name", @search.to_s))
    end
    @public_only = params[:public_only]
    if @public_only
      @courses = @courses.where(is_public: true)
    end
    @open_enrollment_only = params[:open_enrollment_only]
    if @open_enrollment_only
      @courses = @courses.where(open_enrollment: true)
    end
    pagination_args = {}
    pagination_args[:per_page] = 12 unless request.format == :json
    base_url = api_request? ? api_v1_search_all_courses_url : "/search/all_courses/"
    ret = Api.paginate(@courses, self, base_url, pagination_args, { enhanced_return: true })
    @courses = ret[:collection]

    if request.format == :json
      return render json: @courses.as_json
    end

    @prevPage = ret[:hash][:prev]
    @nextPage = ret[:hash][:next]
    @contentHTML = render_to_string(partial: "all_courses_inner")

    if request.xhr?
      set_no_cache_headers
      render html: @contentHTML
    end
  end
end
